# Daily Adaptive Quiz System for Data Engineering

A production-grade system using Prefect for orchestration, delivering adaptive quizzes via Telegram with intelligent difficulty adjustment.

---

## 1. High-Level Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PREFECT ORCHESTRATOR                        │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Daily Quiz Flow (10:00 UTC Schedule)                          │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │ │
│  │  │Generate  │→ │Retrieve  │→ │Send via  │→ │Await     │       │ │
│  │  │Question  │  │User State│  │Telegram  │  │Answer    │       │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │ │
│  │       ↓              ↓              ↓              ↓           │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │ │
│  │  │Validate  │  │Update    │  │Adapt     │  │Send      │       │ │
│  │  │Answer    │  │State     │  │Difficulty│  │Feedback  │       │ │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      PERSISTENCE LAYER (PostgreSQL)                  │
│  Users  |  Questions  |  UserAnswers  |  QuestionHistory  |  Streaks│
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      TELEGRAM BOT (python-telegram-bot)               │
│  Webhook endpoint for answers → Prefect webhook trigger              │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Trigger**: Prefect schedule fires daily at 10:00 UTC
2. **Question Generation**: Generate contextualized question based on user's current difficulty
3. **State Retrieval**: Fetch user's current difficulty, streak, and question history
4. **Delivery**: Send question via Telegram with inline keyboard for 4 options
5. **Answer Collection**: Telegram webhook receives user selection
7. **Validation**: Check answer correctness
8. **State Update**: Persist answer, update streak, adjust difficulty
9. **Feedback**: Send explanation and updated stats

### Key Design Decisions

- **PostgreSQL over Redis/SQLite**: Relational relationships (user→answers→questions) and complex queries for adaptive algorithm favor relational DB
- **Webhook over Polling**: Real-time response, lower latency for feedback loop
- **Prefect Flow per User**: Individual flows enable better observability and retry semantics
- **State Machine Pattern**: Clear state transitions (PENDING→ANSWERED→FEEDBACK_DELIVERED)

---

## 2. Prefect Flow and Task Design

### Main Daily Quiz Flow

```python
from prefect import flow, task, get_run_logger
from prefect.blocks.system import JSON
from prefect.artifacts import create_markdown_artifact
from prefect.concurrency.sync import ConcurrencyLimit
from datetime import datetime, date
from typing import Optional, Dict, Any
import asyncio

@flow(name="daily-quiz-distribution", log_prints=True)
async def distribute_daily_quizzes(
    target_users: Optional[list[str]] = None,
    override_time: Optional[datetime] = None
) -> Dict[str, Any]:
    """
    Master flow orchestrating daily quiz delivery to all active users.
    
    Args:
        target_users: Specific user list (for testing/manual triggers)
        override_time: Override current time (for testing)
    
    Returns:
        Summary of distribution results
    """
    logger = get_run_logger()
    
    # Get all active users if not specified
    if target_users is None:
        target_users = await get_active_users_task()
    
    logger.info(f"Starting daily quiz distribution for {len(target_users)} users")
    
    # Parallel execution with concurrency limit
    results = {}
    concurrency = ConcurrencyLimit("quiz-distribution", max_concurrency=10)
    
    async with concurrency:
        tasks = [
            execute_user_quiz_flow(user_id=user_id, override_time=override_time)
            for user_id in target_users
        ]
        completed = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Aggregate results
    for user_id, result in zip(target_users, completed):
        if isinstance(result, Exception):
            logger.error(f"Quiz failed for {user_id}: {result}")
            results[user_id] = {"status": "error", "error": str(result)}
        else:
            results[user_id] = result
    
    # Create summary artifact
    summary = create_distribution_summary(results)
    await create_markdown_artifact(
        markdown=summary,
        name="Daily Quiz Distribution Summary"
    )
    
    return results


@flow(name="user-quiz-execution", retries=2, retry_delay_seconds=60)
async def execute_user_quiz_flow(
    user_id: str,
    override_time: Optional[datetime] = None,
    question_id: Optional[str] = None
) -> Dict[str, Any]:
    """
    Individual user quiz flow: question delivery and answer handling.
    Can be triggered by schedule (question sending) or webhook (answer receiving).
    
    Args:
        user_id: Telegram user ID
        override_time: Time override for testing
        question_id: Pre-existing question ID (when triggered by answer webhook)
    
    Returns:
        Flow execution status and metrics
    """
    logger = get_run_logger()
    current_time = override_time or datetime.utcnow()
    current_date = current_time.date()
    
    try:
        # Branch based on whether we're sending a question or receiving an answer
        if question_id is None:
            # Path 1: New question delivery
            return await send_new_question(user_id, current_date, logger)
        else:
            # Path 2: Answer processing (triggered by webhook)
            return await process_answer(user_id, question_id, logger)
    
    except Exception as e:
        logger.error(f"Quiz execution failed for user {user_id}: {e}")
        raise


async def send_new_question(user_id: str, current_date: date, logger) -> Dict[str, Any]:
    """Send a new question to the user."""
    
    # Retrieve user state
    user_state = await retrieve_user_state_task(user_id)
    
    # Check if already answered today
    if await check_daily_question_exists_task(user_id, current_date):
        logger.info(f"User {user_id} already has a question for today")
        return {"status": "skipped", "reason": "question_exists"}
    
    # Generate adaptive question
    question_data = await generate_adaptive_question_task(
        user_state=user_state,
        current_date=current_date
    )
    
    # Send via Telegram
    telegram_message_id = await send_question_via_telegram_task(
        user_id=user_id,
        question=question_data["question_text"],
        options=question_data["options"]
    )
    
    # Persist question attempt
    await persist_question_task(
        user_id=user_id,
        question_id=question_data["question_id"],
        telegram_message_id=telegram_message_id,
        difficulty_level=user_state["current_difficulty"],
        sent_at=current_time
    )
    
    return {
        "status": "question_sent",
        "question_id": question_data["question_id"],
        "difficulty": user_state["current_difficulty"],
        "telegram_message_id": telegram_message_id
    }


async def process_answer(user_id: str, question_id: str, logger) -> Dict[str, Any]:
    """Process user's answer to a question."""
    
    # Fetch user's answer (from webhook payload or DB)
    answer_data = await retrieve_answer_task(user_id, question_id)
    
    # Validate answer
    validation_result = await validate_answer_task(
        question_id=question_id,
        user_answer=answer_data["selected_option"],
        logger=logger
    )
    
    # Get current state
    user_state = await retrieve_user_state_task(user_id)
    
    # Calculate new difficulty and streak
    adaptation = await calculate_adaptation_task(
        is_correct=validation_result["is_correct"],
        current_difficulty=user_state["current_difficulty"],
        current_streak=user_state["current_streak"],
        consecutive_correct=user_state["consecutive_correct"],
        logger=logger
    )
    
    # Update user state
    await update_user_state_task(
        user_id=user_id,
        new_difficulty=adaptation["new_difficulty"],
        new_streak=adaptation["new_streak"],
        new_consecutive_correct=adaptation["new_consecutive_correct"]
    )
    
    # Persist answer record
    await persist_answer_task(
        user_id=user_id,
        question_id=question_id,
        selected_option=answer_data["selected_option"],
        is_correct=validation_result["is_correct"],
        time_taken_seconds=answer_data.get("time_taken_seconds")
    )
    
    # Send feedback
    await send_feedback_task(
        user_id=user_id,
        is_correct=validation_result["is_correct"],
        explanation=validation_result["explanation"],
        new_stats={
            "streak": adaptation["new_streak"],
            "difficulty": adaptation["new_difficulty"]
        }
    )
    
    return {
        "status": "answer_processed",
        "is_correct": validation_result["is_correct"],
        "new_streak": adaptation["new_streak"],
        "new_difficulty": adaptation["new_difficulty"]
    }
```

### Task Definitions

```python
@task(retries=3, retry_delay_seconds=[5, 10, 30])
async def retrieve_user_state_task(user_id: str) -> Dict[str, Any]:
    """
    Retrieve user's current state from PostgreSQL.
    """
    # Implementation in Section 5
    pass


@task
async def get_active_users_task() -> list[str]:
    """
    Get list of users who haven't opted out and are in correct timezones.
    """
    # Query users who have opted in to daily quizzes
    # Filter by timezone preference (default: UTC)
    pass


@task
async def check_daily_question_exists_task(user_id: str, quiz_date: date) -> bool:
    """
    Check if user already has a pending or completed question for today.
    """
    pass


@task(timeout_seconds=30)
async def generate_adaptive_question_task(
    user_state: Dict[str, Any],
    current_date: date
) -> Dict[str, Any]:
    """
    Generate question adapted to user's current difficulty level.
    Avoids repeating questions from user history.
    """
    # Get question bank filtered by difficulty
    # Exclude questions already seen by user
    # Select one with appropriate topic distribution
    pass


@task(retries=2, retry_delay_seconds=[5, 10])
async def send_question_via_telegram_task(
    user_id: str,
    question: str,
    options: list[str]
) -> int:
    """
    Send question via Telegram with inline keyboard.
    Returns Telegram message ID.
    """
    pass


@task
async def persist_question_task(
    user_id: str,
    question_id: str,
    telegram_message_id: int,
    difficulty_level: str,
    sent_at: datetime
) -> None:
    """Persist question delivery record."""
    pass


@task
async def retrieve_answer_task(user_id: str, question_id: str) -> Dict[str, Any]:
    """Fetch user's answer from DB (stored by webhook)."""
    pass


@task
async def validate_answer_task(
    question_id: str,
    user_answer: str,
    logger
) -> Dict[str, Any]:
    """Validate answer and return explanation."""
    pass


@task
async def calculate_adaptation_task(
    is_correct: bool,
    current_difficulty: str,
    current_streak: int,
    consecutive_correct: int,
    logger
) -> Dict[str, Any]:
    """Calculate new difficulty and streak based on answer."""
    # Implementation in Section 6
    pass


@task(retries=2)
async def update_user_state_task(
    user_id: str,
    new_difficulty: str,
    new_streak: int,
    new_consecutive_correct: int
) -> None:
    """Update user's state in DB."""
    pass


@task(retries=2)
async def persist_answer_task(
    user_id: str,
    question_id: str,
    selected_option: str,
    is_correct: bool,
    time_taken_seconds: Optional[int]
) -> None:
    """Persist answer record."""
    pass


@task(retries=2)
async def send_feedback_task(
    user_id: str,
    is_correct: bool,
    explanation: str,
    new_stats: Dict[str, Any]
) -> None:
    """Send feedback message with explanation and updated stats."""
    pass
```

### Deployment Configuration

```python
from prefect.deployments import DeploymentSpec
from prefect.orion.schemas.schedules import IntervalSchedule

# Daily deployment - runs at 10:00 UTC every day
daily_deployment = DeploymentSpec(
    name="daily-quiz-production",
    flow_name="daily-quiz-distribution",
    schedule=IntervalSchedule(
        interval=timedelta(days=1),
        anchor_date=datetime(2024, 1, 1, 10, 0, tzinfo=timezone.utc)
    ),
    parameters={},
    tags=["production", "daily", "quiz"],
    description="Daily Data Engineering quiz distribution at 10:00 UTC"
)

# Webhook deployment for answer processing
webhook_deployment = DeploymentSpec(
    name="quiz-answer-webhook",
    flow_name="user-quiz-execution",
    triggers=[
        {
            "type": "webhook",
            "url": "/api/webhooks/quiz-answer"
        }
    ],
    tags=["production", "webhook", "quiz"],
    description="Webhook endpoint for processing quiz answers from Telegram"
)
```

---

## 3. Implementation Code

### Question Generator with LLM

```python
from openai import AsyncOpenAI
import random
from typing import List, Dict, Any
from enum import Enum

class DifficultyLevel(Enum):
    BEGINNER = 1
    INTERMEDIATE = 2
    ADVANCED = 3
    EXPERT = 4

class TopicCategory(Enum):
    DATA_MODELING = "data_modeling"
    SQL_PERFORMANCE = "sql_performance"
    DISTRIBUTED_SYSTEMS = "distributed_systems"
    STREAMING = "streaming"
    DATA_WAREHOUSE_LAKEHOUSE = "data_warehouse_lakehouse"
    ETL_VS_ELT = "etl_vs_elt"
    ORCHESTRATION = "orchestration"
    DATA_QUALITY = "data_quality"
    OBSERVABILITY = "observability"

# Question templates with static fallbacks (if LLM unavailable)
STATIC_QUESTION_BANK = {
    DifficultyLevel.INTERMEDIATE: {
        TopicCategory.SQL_PERFORMANCE: [
            {
                "question": "Which index type would be most effective for a column frequently used in WHERE clauses with exact match queries and rarely in range queries?",
                "options": ["B-Tree", "Hash", "GIN", "GiST"],
                "correct_option": "B-Tree",
                "explanation": "B-Tree indexes are optimized for exact match and range queries. Hash indexes are for exact matches only and don't support ordering or ranges."
            },
            # ... more static questions
        ],
        # ... other topics
    },
    # ... other difficulty levels
}


class QuestionGenerator:
    def __init__(self, openai_client: AsyncOpenAI, db_session):
        self.client = openai_client
        self.db = db_session
    
    async def generate_question(
        self,
        difficulty: DifficultyLevel,
        excluded_question_ids: List[str],
        preferred_topics: Optional[List[TopicCategory]] = None
    ) -> Dict[str, Any]:
        """
        Generate a question adapted to difficulty level, avoiding repeats.
        
        Args:
            difficulty: Target difficulty level
            excluded_question_ids: Questions user has already seen
            preferred_topics: Topics to prioritize (optional)
        
        Returns:
            Question dict with id, question_text, options, correct_option, explanation
        """
        # 1. First check static question bank for quick retrieval
        static_question = self._get_static_question(
            difficulty, excluded_question_ids, preferred_topics
        )
        if static_question:
            return {
                "question_id": f"static_{hash(static_question['question'])}",
                "question_text": static_question["question"],
                "options": static_question["options"],
                "correct_option": static_question["correct_option"],
                "explanation": static_question["explanation"],
                "topic": preferred_topics[0] if preferred_topics else TopicCategory.SQL_PERFORMANCE,
                "difficulty": difficulty.value
            }
        
        # 2. Generate using LLM if static questions exhausted
        return await self._generate_llm_question(
            difficulty, excluded_question_ids, preferred_topics
        )
    
    def _get_static_question(
        self,
        difficulty: DifficultyLevel,
        excluded_ids: List[str],
        preferred_topics: Optional[List[TopicCategory]]
    ) -> Optional[Dict[str, Any]]:
        """Retrieve from static question bank."""
        available_questions = []
        
        if preferred_topics:
            # Prioritize preferred topics
            for topic in preferred_topics:
                if topic in STATIC_QUESTION_BANK.get(difficulty, {}):
                    for q in STATIC_QUESTION_BANK[difficulty][topic]:
                        qid = f"static_{hash(q['question'])}"
                        if qid not in excluded_ids:
                            available_questions.append((q, topic))
        
        # Fallback to all questions at this difficulty
        if not available_questions:
            for topic, questions in STATIC_QUESTION_BANK.get(difficulty, {}).items():
                for q in questions:
                    qid = f"static_{hash(q['question'])}"
                    if qid not in excluded_ids:
                        available_questions.append((q, topic))
        
        if not available_questions:
            return None
        
        question, topic = random.choice(available_questions)
        return question
    
    async def _generate_llm_question(
        self,
        difficulty: DifficultyLevel,
        excluded_ids: List[str],
        preferred_topics: Optional[List[TopicCategory]]
    ) -> Dict[str, Any]:
        """Generate question using OpenAI API."""
        
        topic_str = ", ".join([t.value for t in preferred_topics]) if preferred_topics else "any Data Engineering topic"
        difficulty_desc = self._difficulty_to_description(difficulty)
        
        prompt = f"""Generate a multiple-choice question for Data Engineers.

Requirements:
- Difficulty: {difficulty_desc} ({difficulty.value}/4)
- Topic: {topic_str}
- Question should be technical and practical
- 4 options (A, B, C, D), only one correct
- Include brief explanation (2-3 sentences)
- Avoid generic questions

Format as JSON:
{{
    "question": "text of question",
    "options": ["option A", "option B", "option C", "option D"],
    "correct_option": "option A",  // Must match exactly one option
    "explanation": "explanation text"
}}

Topics to choose from: Data Modeling, SQL Performance, Distributed Systems, Streaming, Data Warehouses/Lakehouses, ETL vs ELT, Orchestration, Data Quality, Observability."""

        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "You are an expert Data Engineer creating technical quiz questions."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                response_format={"type": "json_object"}
            )
            
            content = response.choices[0].message.content
            import json
            question_data = json.loads(content)
            
            # Validate structure
            if len(question_data["options"]) != 4:
                raise ValueError("Must have exactly 4 options")
            
            if question_data["correct_option"] not in question_data["options"]:
                raise ValueError("Correct option must be one of the options")
            
            # Store generated question in DB for reuse
            question_id = await self._persist_generated_question(
                question_data, difficulty, preferred_topics
            )
            
            return {
                "question_id": question_id,
                "question_text": question_data["question"],
                "options": question_data["options"],
                "correct_option": question_data["correct_option"],
                "explanation": question_data["explanation"],
                "topic": preferred_topics[0] if preferred_topics else TopicCategory.SQL_PERFORMANCE,
                "difficulty": difficulty.value
            }
            
        except Exception as e:
            # Fallback to static question if generation fails
            logger.error(f"LLM question generation failed: {e}")
            return self._get_static_question(difficulty, [], preferred_topics) or \
                   self._get_static_question(difficulty, [], None)
    
    def _difficulty_to_description(self, difficulty: DifficultyLevel) -> str:
        descriptions = {
            DifficultyLevel.BEGINNER: "Foundational concepts for junior engineers (1-2 years experience)",
            DifficultyLevel.INTERMEDIATE: "Practical knowledge for mid-level engineers (2-4 years)",
            DifficultyLevel.ADVANCED: "Complex scenarios and optimizations for senior engineers (5-8 years)",
            DifficultyLevel.EXPERT: "Deep system design and trade-off analysis for principal engineers (8+ years)"
        }
        return descriptions[difficulty]
    
    async def _persist_generated_question(
        self,
        question_data: Dict[str, Any],
        difficulty: DifficultyLevel,
        topics: Optional[List[TopicCategory]]
    ) -> str:
        """Store generated question in database for reuse."""
        import uuid
        question_id = str(uuid.uuid4())
        
        await self.db.execute("""
            INSERT INTO questions (id, question_text, options, correct_option, 
                                   explanation, difficulty_level, topic, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
        """, question_id, question_data["question"], 
            question_data["options"], question_data["correct_option"],
            question_data["explanation"], difficulty.value,
            topics[0].value if topics else None)
        
        return question_id
```

### Telegram Bot Integration

```python
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CallbackQueryHandler, ContextTypes
from telegram.constants import ParseMode
import asyncio
from typing import Dict, Any
import json
from aiohttp import web

class QuizTelegramBot:
    def __init__(
        self,
        bot_token: str,
        prefect_api_url: str,
        webhook_url: str
    ):
        self.bot_token = bot_token
        self.prefect_url = prefect_api_url
        self.webhook_url = webhook_url
        self.app = Application.builder().token(bot_token).build()
        
        # Store pending questions for quick lookup (key: telegram_message_id)
        self.pending_questions: Dict[int, Dict[str, Any]] = {}
    
    async def setup_handlers(self):
        """Setup Telegram bot handlers."""
        self.app.add_handler(CallbackQueryHandler(self.handle_answer))
    
    async def send_question(
        self,
        user_id: str,
        question_text: str,
        options: List[str],
        question_id: str
    ) -> int:
        """
        Send question with inline keyboard.
        Returns Telegram message ID.
        """
        # Create inline keyboard with options
        keyboard = [
            [InlineKeyboardButton(option, callback_data=f"{question_id}:{i}")]
            for i, option in enumerate(options)
        ]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        # Format question text
        formatted_text = (
            f"*📊 Data Engineering Daily Quiz*\n\n"
            f"{question_text}\n\n"
            f"Tap an option to answer!"
        )
        
        # Send message
        async with self.app.bot:
            message = await self.app.bot.send_message(
                chat_id=user_id,
                text=formatted_text,
                parse_mode=ParseMode.MARKDOWN,
                reply_markup=reply_markup
            )
        
        # Store pending question for quick validation
        self.pending_questions[message.message_id] = {
            "question_id": question_id,
            "options": options
        }
        
        return message.message_id
    
    async def handle_answer(
        self,
        update: Update,
        context: ContextTypes.DEFAULT_TYPE
    ) -> None:
        """
        Handle user's answer selection.
        Triggers Prefect flow for answer processing.
        """
        query = update.callback_query
        await query.answer()  # Acknowledge the callback
        
        # Parse callback data: format "question_id:option_index"
        try:
            question_id, option_index = query.data.split(":")
            option_index = int(option_index)
        except (ValueError, AttributeError):
            await query.edit_message_text("⚠️ Invalid answer format. Please try a new question.")
            return
        
        user_id = str(query.from_user.id)
        telegram_message_id = query.message.message_id
        
        # Get the pending question
        pending = self.pending_questions.get(telegram_message_id)
        if not pending:
            await query.edit_message_text("⚠️ This question has expired or is no longer available.")
            return
        
        selected_option = pending["options"][option_index]
        
        # Store answer in database (will be retrieved by Prefect flow)
        await self._store_answer(
            user_id=user_id,
            question_id=question_id,
            telegram_message_id=telegram_message_id,
            selected_option=selected_option,
            answered_at=datetime.utcnow()
        )
        
        # Trigger Prefect flow via webhook
        await self._trigger_prefect_flow(
            user_id=user_id,
            question_id=question_id
        )
        
        # Send "Processing..." message
        await query.edit_message_text("⏳ Checking your answer...")
    
    async def send_feedback(
        self,
        user_id: str,
        is_correct: bool,
        explanation: str,
        new_stats: Dict[str, Any],
        telegram_message_id: int
    ) -> None:
        """
        Send feedback with explanation and updated stats.
        """
        emoji = "✅" if is_correct else "❌"
        status = "Correct!" if is_correct else "Incorrect"
        
        difficulty_labels = {
            1: "🌱 Beginner",
            2: "🌿 Intermediate", 
            3: "🌳 Advanced",
            4: "🏔️ Expert"
        }
        
        feedback_text = (
            f"{emoji} *{status}*\n\n"
            f"*Explanation:*\n{explanation}\n\n"
            f"*Your Stats:*\n"
            f"🔥 Streak: {new_stats['streak']} days\n"
            f"📈 Difficulty: {difficulty_labels.get(new_stats['difficulty'], 'Unknown')}\n\n"
            f"See you tomorrow at 10:00 UTC for your next question! 🚀"
        )
        
        async with self.app.bot:
            await self.app.bot.edit_message_text(
                chat_id=user_id,
                message_id=telegram_message_id,
                text=feedback_text,
                parse_mode=ParseMode.MARKDOWN
            )
    
    async def send_daily_reminder(self, user_id: str, pending_question: Dict[str, Any]) -> None:
        """
        Send reminder for unanswered questions (optional feature).
        """
        reminder_text = (
            f"⏰ *Reminder: You have a pending quiz question!*\n\n"
            f"Answer now to maintain your streak 🔥"
        )
        
        async with self.app.bot:
            await self.app.bot.send_message(
                chat_id=user_id,
                text=reminder_text,
                parse_mode=ParseMode.MARKDOWN
            )
    
    async def _store_answer(
        self,
        user_id: str,
        question_id: str,
        telegram_message_id: int,
        selected_option: str,
        answered_at: datetime
    ) -> None:
        """
        Store answer in database for Prefect retrieval.
        """
        # Implementation depends on DB setup - see Section 5
        pass
    
    async def _trigger_prefect_flow(
        self,
        user_id: str,
        question_id: str
    ) -> None:
        """
        Trigger Prefect flow via webhook.
        """
        import aiohttp
        
        payload = {
            "user_id": user_id,
            "question_id": question_id
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.prefect_url}/api/deployments/quiz-answer-webhook/create_flow_run",
                json=payload
            ) as response:
                if response.status != 201:
                    raise Exception(f"Failed to trigger Prefect flow: {response.status}")
    
    async def start_webhook(self, port: int = 8080):
        """Start webhook server."""
        await self.app.initialize()
        await self.app.start()
        await self.app.updater.start_webhook(
            listen="0.0.0.0",
            port=port,
            url_path="webhook",
            webhook_url=f"{self.webhook_url}/webhook"
        )
        logger.info(f"Telegram webhook started on port {port}")
    
    async def shutdown(self):
        """Cleanup resources."""
        await self.app.updater.stop()
        await self.app.stop()
        await self.app.shutdown()


# Webhook route for Prefect integration
async def prefect_webhook_handler(request: web.Request) -> web.Response:
    """
    Prefect webhook endpoint for answer processing.
    This can also be called directly by Telegram bot.
    """
    payload = await request.json()
    user_id = payload.get("user_id")
    question_id = payload.get("question_id")
    
    # Trigger Prefect flow
    # This would typically be done via Prefect's REST API
    # For simplicity, we're showing the pattern
    
    return web.json_response({"status": "triggered"})


async def run_bot(
    bot_token: str,
    prefect_api_url: str,
    webhook_url: str,
    port: int = 8080
):
    """Main entry point for running the bot."""
    bot = QuizTelegramBot(bot_token, prefect_api_url, webhook_url)
    await bot.setup_handlers()
    
    # Setup aiohttp web server for Prefect webhook
    web_app = web.Application()
    web_app.router.add_post("/webhook", lambda r: bot.app.update_queue.put_nowait(await r.json()))
    web_app.router.add_post("/prefect-webhook", prefect_webhook_handler)
    
    # Start
    runner = web.AppRunner(web_app)
    await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", port)
    await site.start()
    
    logger.info(f"Bot server running on port {port}")
    
    try:
        await asyncio.Event().wait()  # Run forever
    finally:
        await bot.shutdown()
        await runner.cleanup()
```

---

## 4. Data Model (PostgreSQL)

### Schema Definition

```sql
-- Users table: stores quiz participant state
CREATE TABLE users (
    user_id VARCHAR(255) PRIMARY KEY,  -- Telegram user ID
    username VARCHAR(255),
    current_difficulty INTEGER NOT NULL DEFAULT 2,  -- 1=Beginner, 2=Intermediate, 3=Advanced, 4=Expert
    current_streak INTEGER NOT NULL DEFAULT 0,
    consecutive_correct INTEGER NOT NULL DEFAULT 0,
    total_questions_answered INTEGER NOT NULL DEFAULT 0,
    total_correct_answers INTEGER NOT NULL DEFAULT 0,
    timezone VARCHAR(50) DEFAULT 'UTC',
    opt_in_daily_quiz BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_difficulty CHECK (current_difficulty BETWEEN 1 AND 4),
    CONSTRAINT valid_streak CHECK (current_streak >= 0)
);

-- Questions table: question bank (static and LLM-generated)
CREATE TABLE questions (
    id VARCHAR(255) PRIMARY KEY,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,  -- Array of 4 option strings
    correct_option TEXT NOT NULL,  -- Must match one of the options
    explanation TEXT NOT NULL,
    difficulty_level INTEGER NOT NULL,
    topic VARCHAR(100),
    is_static BOOLEAN NOT NULL DEFAULT FALSE,  -- True for hardcoded questions
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),  -- 'system' or LLM model name
    
    CONSTRAINT valid_options CHECK (jsonb_array_length(options) = 4),
    CONSTRAINT option_in_options CHECK (correct_option = ANY(options))
);

-- Index for efficient question filtering
CREATE INDEX idx_questions_difficulty ON questions(difficulty_level);
CREATE INDEX idx_questions_topic ON questions(topic);
CREATE INDEX idx_questions_static ON questions(is_static);

-- UserQuestions table: tracks questions sent to each user
CREATE TABLE user_questions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    question_id VARCHAR(255) NOT NULL REFERENCES questions(id),
    telegram_message_id INTEGER NOT NULL,  -- For updating the message
    sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    answered_at TIMESTAMP WITH TIME ZONE,
    answer_received BOOLEAN NOT NULL DEFAULT FALSE,
    
    CONSTRAINT uk_user_question UNIQUE (user_id, sent_at::date)  -- One question per user per day
);

CREATE INDEX idx_user_questions_user_date ON user_questions(user_id, sent_at::date);
CREATE INDEX idx_user_questions_answered ON user_questions(answer_received) 
    WHERE answered_at IS NULL;  -- For finding unanswered questions

-- UserAnswers table: detailed answer records
CREATE TABLE user_answers (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    question_id VARCHAR(255) NOT NULL REFERENCES questions(id),
    user_question_id INTEGER NOT NULL REFERENCES user_questions(id) ON DELETE CASCADE,
    selected_option TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    time_taken_seconds INTEGER,  -- Optional: how long they took to answer
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    difficulty_level INTEGER NOT NULL,  -- Snapshot of difficulty when answered
    streak_before INTEGER NOT NULL,  -- Snapshot of streak before this answer
    streak_after INTEGER NOT NULL  -- Streak after this answer
);

CREATE INDEX idx_user_answers_user ON user_answers(user_id);
CREATE INDEX idx_user_answers_correctness ON user_answers(is_correct);
CREATE INDEX idx_user_answers_date ON user_answers(answered_at::date);

-- StreakHistory table: tracks streak changes (for analytics)
CREATE TABLE streak_history (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    streak_date DATE NOT NULL,
    streak_value INTEGER NOT NULL,
    streak_action VARCHAR(20) NOT NULL,  -- 'increment', 'reset', 'maintain'
    reason VARCHAR(255),  -- Why streak changed (e.g., 'correct_answer', 'incorrect_answer', 'day_missed')
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uk_user_date UNIQUE (user_id, streak_date)
);

CREATE INDEX idx_streak_history_user ON streak_history(user_id, streak_date);

-- TopicPerformance table: tracks performance per topic
CREATE TABLE topic_performance (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    questions_attempted INTEGER NOT NULL DEFAULT 0,
    questions_correct INTEGER NOT NULL DEFAULT 0,
    last_attempted_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uk_user_topic UNIQUE (user_id, topic)
);

CREATE INDEX idx_topic_performance_user ON topic_performance(user_id);

-- Views for analytics
CREATE VIEW user_quiz_summary AS
SELECT 
    u.user_id,
    u.username,
    u.current_difficulty,
    u.current_streak,
    COUNT(DISTINCT ua.question_id) as total_answers,
    SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) as correct_answers,
    ROUND(SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::numeric / 
          NULLIF(COUNT(DISTINCT ua.question_id), 0) * 100, 2) as accuracy_pct
FROM users u
LEFT JOIN user_answers ua ON u.user_id = ua.user_id
WHERE u.opt_in_daily_quiz = TRUE
GROUP BY u.user_id, u.username, u.current_difficulty, u.current_streak;

CREATE VIEW daily_question_stats AS
SELECT 
    DATE(sent_at) as quiz_date,
    COUNT(DISTINCT user_id) as questions_sent,
    COUNT(DISTINCT CASE WHEN answered_at IS NOT NULL THEN user_id END) as answered,
    COUNT(DISTINCT CASE WHEN answered_at IS NULL THEN user_id END) as unanswered,
    ROUND(
        COUNT(DISTINCT CASE WHEN answered_at IS NOT NULL THEN user_id END)::numeric /
        NULLIF(COUNT(DISTINCT user_id), 0) * 100, 2
    ) as response_rate_pct
FROM user_questions
GROUP BY DATE(sent_at)
ORDER BY quiz_date DESC;

-- Functions and triggers
CREATE OR REPLACE FUNCTION update_user_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_update_timestamp
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_user_timestamp();

-- Function to get next question (avoiding repeats)
CREATE OR REPLACE FUNCTION get_next_adaptive_question(
    p_user_id VARCHAR,
    p_difficulty INTEGER,
    p_excluded_ids VARCHAR[]
) RETURNS TABLE (
    question_id VARCHAR,
    question_text TEXT,
    options JSONB,
    correct_option TEXT,
    explanation TEXT,
    topic VARCHAR,
    difficulty_level INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT q.id, q.question_text, q.options, q.correct_option, q.explanation, q.topic, q.difficulty_level
    FROM questions q
    WHERE q.difficulty_level = p_difficulty
      AND (p_excluded_ids IS NULL OR q.id = ANY(p_excluded_ids) = FALSE)
      AND q.id NOT IN (
          SELECT ua.question_id
          FROM user_answers ua
          WHERE ua.user_id = p_user_id
      )
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to update topic performance
CREATE OR REPLACE FUNCTION update_topic_performance(
    p_user_id VARCHAR,
    p_question_id VARCHAR,
    p_is_correct BOOLEAN
) RETURNS VOID AS $$
DECLARE
    v_topic VARCHAR(100);
BEGIN
    SELECT topic INTO v_topic
    FROM questions
    WHERE id = p_question_id;
    
    IF v_topic IS NULL THEN
        RETURN;
    END IF;
    
    INSERT INTO topic_performance (user_id, topic, questions_attempted, questions_correct, last_attempted_at)
    VALUES (p_user_id, v_topic, 1, CASE WHEN p_is_correct THEN 1 ELSE 0 END, NOW())
    ON CONFLICT (user_id, topic) DO UPDATE
    SET 
        questions_attempted = topic_performance.questions_attempted + 1,
        questions_correct = topic_performance.questions_correct + 
            CASE WHEN p_is_correct THEN 1 ELSE 0 END,
        last_attempted_at = NOW(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
```

### Database Connection and Queries

```python
import asyncpg
from typing import List, Dict, Any, Optional
from datetime import date, datetime

class QuizRepository:
    """Repository for all quiz-related database operations."""
    
    def __init__(self, db_url: str):
        self.db_url = db_url
        self.pool: Optional[asyncpg.Pool] = None
    
    async def initialize(self):
        """Initialize connection pool."""
        self.pool = await asyncpg.create_pool(self.db_url, min_size=5, max_size=20)
    
    async def close(self):
        """Close connection pool."""
        if self.pool:
            await self.pool.close()
    
    async def get_user_state(self, user_id: str) -> Dict[str, Any]:
        """Retrieve user's current state."""
        query = """
            SELECT 
                user_id,
                username,
                current_difficulty,
                current_streak,
                consecutive_correct,
                total_questions_answered,
                total_correct_answers,
                timezone
            FROM users
            WHERE user_id = $1 AND opt_in_daily_quiz = TRUE
        """
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, user_id)
            if not row:
                raise ValueError(f"User {user_id} not found or not opted in")
            
            return dict(row)
    
    async def create_user_if_not_exists(
        self,
        user_id: str,
        username: Optional[str] = None
    ) -> None:
        """Create user if doesn't exist."""
        query = """
            INSERT INTO users (user_id, username, current_difficulty)
            VALUES ($1, $2, 2)
            ON CONFLICT (user_id) DO NOTHING
        """
        
        async with self.pool.acquire() as conn:
            await conn.execute(query, user_id, username)
    
    async def get_active_users(self) -> List[str]:
        """Get list of opted-in users."""
        query = """
            SELECT user_id
            FROM users
            WHERE opt_in_daily_quiz = TRUE
            ORDER BY user_id
        """
        
        async with self.pool.acquire() as conn:
            rows = await conn.fetch(query)
            return [row["user_id"] for row in rows]
    
    async def check_daily_question_exists(
        self,
        user_id: str,
        quiz_date: date
    ) -> bool:
        """Check if user already has a question for the given date."""
        query = """
            SELECT EXISTS(
                SELECT 1
                FROM user_questions
                WHERE user_id = $1 
                  AND sent_at::date = $2
            )
        """
        
        async with self.pool.acquire() as conn:
            return await conn.fetchval(query, user_id, quiz_date)
    
    async def get_next_adaptive_question(
        self,
        user_id: str,
        difficulty: int
    ) -> Optional[Dict[str, Any]]:
        """Get next question for user, avoiding repeats."""
        
        # First, get questions user has already answered
        excluded_query = """
            SELECT DISTINCT question_id
            FROM user_answers
            WHERE user_id = $1
        """
        
        async with self.pool.acquire() as conn:
            excluded = [row["question_id"] for row in await conn.fetch(excluded_query, user_id)]
            
            # Get next question using our function
            question_query = """
                SELECT * FROM get_next_adaptive_question($1, $2, $3)
            """
            
            row = await conn.fetchrow(question_query, user_id, difficulty, excluded)
            if row:
                return dict(row)
            
            # Fallback: no questions left at this difficulty, get any question
            fallback_query = """
                SELECT id, question_text, options, correct_option, explanation, topic, difficulty_level
                FROM questions
                WHERE id NOT IN (SELECT question_id FROM user_answers WHERE user_id = $1)
                ORDER BY RANDOM()
                LIMIT 1
            """
            
            row = await conn.fetchrow(fallback_query, user_id)
            return dict(row) if row else None
    
    async def persist_question(
        self,
        user_id: str,
        question_id: str,
        telegram_message_id: int,
        difficulty_level: int
    ) -> int:
        """Persist question delivery record. Returns user_question_id."""
        query = """
            INSERT INTO user_questions (user_id, question_id, telegram_message_id, difficulty_level)
            VALUES ($1, $2, $3, $4)
            RETURNING id
        """
        
        async with self.pool.acquire() as conn:
            return await conn.fetchval(query, user_id, question_id, telegram_message_id, difficulty_level)
    
    async def store_answer(
        self,
        user_id: str,
        question_id: str,
        telegram_message_id: int,
        selected_option: str
    ) -> None:
        """Store user's answer (called by webhook)."""
        query = """
            UPDATE user_questions
            SET answered_at = NOW(), answer_received = TRUE
            WHERE user_id = $1 
              AND telegram_message_id = $2
              AND question_id = $3
        """
        
        async with self.pool.acquire() as conn:
            result = await conn.execute(query, user_id, telegram_message_id, question_id)
            if result == "UPDATE 0":
                raise ValueError("Question not found or already answered")
    
    async def get_stored_answer(
        self,
        user_id: str,
        question_id: str
    ) -> Optional[Dict[str, Any]]:
        """Retrieve stored answer for Prefect processing."""
        query = """
            SELECT uq.user_question_id, ua.answered_at, 
                   EXTRACT(EPOCH FROM (ua.answered_at - uq.sent_at)) as time_taken_seconds
            FROM (
                SELECT uq.id as user_question_id, uq.sent_at
                FROM user_questions uq
                WHERE uq.user_id = $1 AND uq.question_id = $2
            ) uq
            CROSS JOIN user_answers ua
            WHERE ua.user_question_id = uq.user_question_id
        """
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, user_id, question_id)
            # This is simplified - in practice, answer storage needs a dedicated table
            return dict(row) if row else None
    
    async def update_user_state(
        self,
        user_id: str,
        new_difficulty: int,
        new_streak: int,
        new_consecutive_correct: int
    ) -> None:
        """Update user's state."""
        query = """
            UPDATE users
            SET 
                current_difficulty = $2,
                current_streak = $3,
                consecutive_correct = $4,
                updated_at = NOW()
            WHERE user_id = $1
        """
        
        async with self.pool.acquire() as conn:
            await conn.execute(query, user_id, new_difficulty, new_streak, new_consecutive_correct)
    
    async def persist_answer(
        self,
        user_id: str,
        question_id: str,
        user_question_id: int,
        selected_option: str,
        is_correct: bool,
        time_taken_seconds: Optional[int],
        difficulty_level: int,
        streak_before: int,
        streak_after: int
    ) -> None:
        """Persist answer record."""
        query = """
            INSERT INTO user_answers (
                user_id, question_id, user_question_id, selected_option,
                is_correct, time_taken_seconds, difficulty_level,
                streak_before, streak_after
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        """
        
        async with self.pool.acquire() as conn:
            await conn.execute(
                query,
                user_id, question_id, user_question_id, selected_option,
                is_correct, time_taken_seconds, difficulty_level,
                streak_before, streak_after
            )
    
    async def record_streak_change(
        self,
        user_id: str,
        streak_date: date,
        streak_value: int,
        streak_action: str,
        reason: Optional[str] = None
    ) -> None:
        """Record streak change in history."""
        query = """
            INSERT INTO streak_history (user_id, streak_date, streak_value, streak_action, reason)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (user_id, streak_date) DO UPDATE
            SET streak_value = $3, streak_action = $4, reason = $5
        """
        
        async with self.pool.acquire() as conn:
            await conn.execute(query, user_id, streak_date, streak_value, streak_action, reason)
    
    async def get_streak_info(
        self,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get streak information for validation."""
        query = """
            SELECT 
                current_streak,
                consecutive_correct,
                (SELECT MAX(streak_date) FROM streak_history WHERE user_id = $1) as last_answered_date
            FROM users
            WHERE user_id = $1
        """
        
        async with self.pool.acquire() as conn:
            row = await conn.fetchrow(query, user_id)
            return dict(row) if row else None
```

---

## 5. Adaptive Difficulty Algorithm

### Difficulty Adaptation Logic

```python
from typing import Dict, Tuple
from datetime import date
from enum import Enum

class DifficultyLevel(Enum):
    BEGINNER = 1
    INTERMEDIATE = 2
    ADVANCED = 3
    EXPERT = 4

class DifficultyAdapter:
    """
    Implements adaptive difficulty algorithm.
    
    Principles:
    1. Gradual progression - don't jump multiple levels
    2. Consecutive correct answers increase difficulty
    3. Incorrect answers decrease or maintain difficulty
    4. Bounded progression (1-4)
    5. Streak reset on incorrect answer or missed day
    """
    
    # Configuration
    CORRECT_THRESHOLD_FOR_PROMOTION = 3  # Consecutive correct answers needed
    INCORRECT_THRESHOLD_FOR_DEMOTION = 1  # Immediate reset on incorrect
    
    def __init__(self, logger):
        self.logger = logger
    
    def calculate_adaptation(
        self,
        is_correct: bool,
        current_difficulty: DifficultyLevel,
        current_streak: int,
        consecutive_correct: int,
        last_answer_date: Optional[date] = None,
        current_date: Optional[date] = None
    ) -> Tuple[DifficultyLevel, int, int]:
        """
        Calculate new difficulty and streak based on answer.
        
        Args:
            is_correct: Whether the user answered correctly
            current_difficulty: Current difficulty level
            current_streak: Current daily streak
            consecutive_correct: Current streak of consecutive correct answers
            last_answer_date: Date of last answered question (for day gap check)
            current_date: Today's date
        
        Returns:
            Tuple of (new_difficulty, new_streak, new_consecutive_correct)
        """
        
        current_date = current_date or date.today()
        
        # Check if day was skipped (streak reset)
        if last_answer_date and (current_date - last_answer_date).days > 1:
            self.logger.info(
                f"Day skipped (last: {last_answer_date}, current: {current_date}), resetting streak"
            )
            return DifficultyLevel.BEGINNER, 0, 0
        
        if is_correct:
            return self._handle_correct_answer(
                current_difficulty,
                current_streak,
                consecutive_correct,
                last_answer_date
            )
        else:
            return self._handle_incorrect_answer(
                current_difficulty,
                current_streak
            )
    
    def _handle_correct_answer(
        self,
        current_difficulty: DifficultyLevel,
        current_streak: int,
        consecutive_correct: int,
        last_answer_date: Optional[date]
    ) -> Tuple[DifficultyLevel, int, int]:
        """
        Handle correct answer logic.
        
        Rules:
        1. Increment streak if answered on same day (or first answer)
        2. Increment consecutive correct count
        3. Promote difficulty after threshold reached
        """
        self.logger.info(
            f"Correct answer - difficulty: {current_difficulty}, "
            f"streak: {current_streak}, consecutive: {consecutive_correct}"
        )
        
        # Update streak
        current_date = date.today()
        if last_answer_date and last_answer_date == current_date:
            # Already answered today, streak unchanged
            new_streak = current_streak
        else:
            # First answer today, increment streak
            new_streak = current_streak + 1
        
        # Update consecutive correct
        new_consecutive_correct = consecutive_correct + 1
        
        # Check for difficulty promotion
        new_difficulty = current_difficulty
        if new_consecutive_correct >= self.CORRECT_THRESHOLD_FOR_PROMOTION:
            if current_difficulty != DifficultyLevel.EXPERT:
                new_difficulty = DifficultyLevel(current_difficulty.value + 1)
                self.logger.info(
                    f"Promoting difficulty: {current_difficulty} → {new_difficulty}"
                )
                new_consecutive_correct = 0  # Reset after promotion
            else:
                self.logger.info("Already at expert difficulty, maintaining")
        
        return new_difficulty, new_streak, new_consecutive_correct
    
    def _handle_incorrect_answer(
        self,
        current_difficulty: DifficultyLevel,
        current_streak: int
    ) -> Tuple[DifficultyLevel, int, int]:
        """
        Handle incorrect answer logic.
        
        Rules:
        1. Reset streak to 0
        2. Reset consecutive correct to 0
        3. Decrease difficulty if not at beginner
        """
        self.logger.info(
            f"Incorrect answer - difficulty: {current_difficulty}, "
            f"streak: {current_streak}"
        )
        
        # Reset streak
        new_streak = 0
        
        # Reset consecutive correct
        new_consecutive_correct = 0
        
        # Decrease difficulty (if not beginner)
        new_difficulty = current_difficulty
        if current_difficulty != DifficultyLevel.BEGINNER:
            new_difficulty = DifficultyLevel(current_difficulty.value - 1)
            self.logger.info(
                f"Demoting difficulty: {current_difficulty} → {new_difficulty}"
            )
        else:
            self.logger.info("Already at beginner difficulty, maintaining")
        
        return new_difficulty, new_streak, new_consecutive_correct


# Integration with Prefect task
@task
async def calculate_adaptation_task(
    is_correct: bool,
    current_difficulty: str,
    current_streak: int,
    consecutive_correct: int,
    last_answer_date: Optional[str],
    logger
) -> Dict[str, Any]:
    """
    Prefect task wrapper for difficulty adaptation.
    
    Args:
        is_correct: Answer correctness
        current_difficulty: Current difficulty as string ("1", "2", "3", "4")
        current_streak: Current streak
        consecutive_correct: Consecutive correct count
        last_answer_date: Last answer date as ISO string
        logger: Prefect logger
    
    Returns:
        Dict with new_difficulty (as string), new_streak, new_consecutive_correct
    """
    from datetime import datetime
    
    adapter = DifficultyAdapter(logger)
    
    current_diff_enum = DifficultyLevel(int(current_difficulty))
    last_date = datetime.fromisoformat(last_answer_date).date() if last_answer_date else None
    
    new_diff, new_streak, new_consec = adapter.calculate_adaptation(
        is_correct=is_correct,
        current_difficulty=current_diff_enum,
        current_streak=current_streak,
        consecutive_correct=consecutive_correct,
        last_answer_date=last_date
    )
    
    return {
        "new_difficulty": str(new_diff.value),
        "new_streak": new_streak,
        "new_consecutive_correct": new_consec
    }
```

### Algorithm Visualized

```
Difficulty Progression State Machine:

Current State        Correct Answer (3x consec)    Incorrect Answer
─────────────────    ──────────────────────────    ─────────────────
    Beginner (1)    ───────────────────────────▶  Intermediate (2)     │
    │                ────────────────────────────▶  Beginner (1)        │
    ▼                                                                  │
Intermediate (2)   ───────────────────────────▶   Advanced (3)        │
    │                ────────────────────────────▶  Beginner (1)        │
    ▼                                                                  │
    Advanced (3)    ───────────────────────────▶    Expert (4)          │
    │                ────────────────────────────▶  Intermediate (2)    │
    ▼                                                                  │
    Expert (4)      ───────────────────────────▶    Expert (4)         │
    │                ────────────────────────────▶  Advanced (3)       │
    └──────────────────────────────────────────────────────────────────┘

Streak Logic:
┌──────────────┐    Correct      ┌──────────────┐
│   Streak: N  │  ──────────▶   │   Streak: N+1│ (if first answer of day)
└──────────────┘                 └──────────────┘

┌──────────────┐    Incorrect    ┌──────────────┐
│   Streak: N  │  ──────────▶   │   Streak: 0   │
└──────────────┘                 └──────────────┘

┌──────────────┐    Day Skipped  ┌──────────────┐
│   Streak: N  │  ──────────▶   │   Streak: 0   │
└──────────────┘                 └──────────────┘
```

---

## 6. Persistence Layer Trade-off Analysis

### Comparison Matrix

| Aspect | PostgreSQL (Chosen) | Redis (Key-Value) | Prefect Blocks | SQLite |
|--------|--------------------|-------------------|----------------|--------|
| **Data Model** | ✅ Rich relational, joins | ❌ Simple KV pairs | ⚠️ Limited schemas | ✅ Lightweight relational |
| **Query Capability** | ✅ Complex queries, aggregation | ⚠️ Limited key lookups | ❌ Very limited | ⚠️ Limited joins |
| **Adaptive Algorithm** | ✅ Easy to implement | ❌ Requires app-side logic | ❌ Not suitable | ⚠️ Possible but slower |
| **Question Exclusion** | ✅ Efficient subqueries | ⚠️ Requires separate storage | ❌ Not feasible | ⚠️ Slower on large datasets |
| **Analytics/Reporting** | ✅ Excellent (views, aggregations) | ❌ Requires ETL | ⚠️ Via Prefect UI only | ⚠️ Basic queries |
| **Performance** | ⚠️ Moderate (network round trips) | ✅ Excellent (in-memory) | ⚠️ Depends on backend | ✅ Excellent (local) |
| **Scalability** | ✅ Horizontal scaling + read replicas | ✅ Redis Cluster | ⚠️ Not designed for scale | ❌ Single-writer |
| **Transaction Support** | ✅ ACID guarantees | ⚠️ Limited transactions | ❌ Not applicable | ✅ ACID guarantees |
| **Backup/Restore** | ✅ pg_dump, point-in-time recovery | ✅ RDB/AOF files | ⚠️ Via Prefect backend | ✅ Simple file copy |
| **Operational Complexity** | ⚠️ Moderate (Postgres management) | ⚠️ Moderate (Redis management) | ✅ Zero config | ✅ Zero config |
| **Cost** | ⚠️ Moderate (cloud RDS) | ⚠️ Moderate (ElastiCache) | ✅ Included in Prefect | ✅ Free (local) |
| **Concurrent Writes** | ✅ Row-level locking | ✅ Optimized for concurrency | ⚠️ Depends on backend | ❌ Single writer |

### Detailed Analysis

#### PostgreSQL (Recommended)

**Strengths:**
1. **Rich Query Language**: Adaptive difficulty algorithm requires complex queries:
   - Joining user state with answer history
   - Filtering questions by exclusion criteria
   - Aggregating performance metrics per topic
   
2. **Data Integrity**: ACID guarantees ensure consistency:
   - No race conditions when updating streaks
   - Transactional question + answer persistence
   - Foreign key constraints prevent orphaned records

3. **Scalability**: 
   - Read replicas for analytics queries
   - Connection pooling (pgBouncer) for high concurrency
   - Partitioning by user_id for multi-tenant scaling

4. **Analytics**: Built-in support for:
   - Views for common aggregations
   - Window functions for streak calculation
   - Materialized views for performance

**Weaknesses:**
- Network latency for each query (mitigated by connection pooling)
- Requires database maintenance (vacuum, indexing)
- Higher cost for cloud-managed instances

**Use Case Alignment:**
- ✅ Question exclusion (complex subqueries)
- ✅ Adaptive difficulty (requires historical data)
- ✅ Streak tracking (date-based logic)
- ✅ Analytics/reporting (dashboards, performance metrics)

#### Redis (Key-Value Store)

**Strengths:**
1. **Performance**: Sub-millisecond reads for hot data
2. **Simplicity**: Simple SET/GET operations
3. **Caching**: Can cache question bank, user states

**Weaknesses:**
1. **Complex Queries Limited**: 
   - No JOINs - must fetch related data separately
   - Question exclusion requires storing large sets
   - Streak history queries are inefficient
   
2. **Data Modeling Overhead**: 
   - Must denormalize data (duplicate user state across keys)
   - No foreign key constraints
   - Manual transaction coordination

3. **Persistence**: 
   - Requires separate RDB for long-term storage
   - AOF/RDB snapshots are bulk operations

**When to Use:**
- As a cache layer on top of PostgreSQL
- For rate limiting and session management
- For pub/sub between Prefect workers

**Implementation Complexity:**
```
User state in Redis:
user:12345:state → {difficulty: 2, streak: 5}

Question exclusion:
user:12345:seen_questions → Set[question_id_1, question_id_2, ...]

Problem: Must also persist to DB for analytics → dual-write complexity
```

#### Prefect Blocks

**Strengths:**
- Zero setup for simple state storage
- Integrated with Prefect UI for inspection
- Supports JSON, secret, and custom blocks

**Weaknesses:**
1. **Not a Database**: 
   - No querying capabilities beyond key lookups
   - No transactions across blocks
   - No relationships or constraints
   
2. **Limited Scalability**:
   - Synchronous API calls to Prefect server
   - Rate limited (subject to Prefect API limits)
   - Not designed for high-frequency reads/writes

3. **Poor Query Support**:
   - Cannot filter users by criteria
   - Cannot aggregate data across users
   - Cannot join related entities

**When to Use:**
- System configuration (bot tokens, API keys)
- Flow-specific parameters (question bank metadata)
- Small, infrequently accessed state

**Anti-Pattern Example:**
```python
# DON'T DO THIS
async def get_seen_questions(user_id: str) -> list[str]:
    # This would require loading entire block and filtering
    block = await JSON.load(f"user-{user_id}-questions")
    return block.value.get("seen_questions", [])

# Instead, use PostgreSQL:
# SELECT question_id FROM user_answers WHERE user_id = $1
```

#### SQLite

**Strengths:**
- Zero operational overhead (single file)
- Excellent for development and testing
- Full SQL support with ACID guarantees

**Weaknesses:**
1. **Concurrency**: Single-writer lock causes contention under load
2. **Network Access**: Cannot be shared across workers (unless via NFS)
3. **Scaling**: Not suitable for distributed systems

**When to Use:**
- Development and local testing
- Single-tenant deployments with low QPS
- Edge computing with isolated workloads

### Final Recommendation: PostgreSQL

**Rationale:**

1. **Query Complexity**: Adaptive difficulty algorithm and question exclusion require:
   ```sql
   -- Questions user hasn't seen, filtered by difficulty
   SELECT * FROM questions 
   WHERE difficulty_level = $1
     AND id NOT IN (
         SELECT question_id FROM user_answers WHERE user_id = $2
     )
   ORDER BY RANDOM() LIMIT 1
   ```
   This query is straightforward in SQL but would require multiple Redis round-trips.

2. **Data Relationships**: System has clear relational model:
   - Users → Questions (many-to-many via user_answers)
   - Users → StreakHistory (one-to-many)
   - Questions → TopicPerformance (aggregated per user)
   
3. **Analytics Requirements**: Need real-time dashboards:
   - Daily question completion rates
   - Per-topic accuracy metrics
   - Difficulty distribution across users

4. **Operational Simplicity**: Single database vs. hybrid Redis+PostgreSQL architecture

**Optimization Strategy:**

```python
# Cache user state in Redis for 5 minutes
async def get_user_state_cached(user_id: str) -> Dict[str, Any]:
    cache_key = f"user_state:{user_id}"
    cached = await redis.get(cache_key)
    
    if cached:
        return json.loads(cached)
    
    # Cache miss - fetch from Postgres
    state = await repo.get_user_state(user_id)
    await redis.setex(cache_key, 300, json.dumps(state))
    return state

# Pre-generate question index (avoid random() on every request)
async def rebuild_question_index():
    """Materialized view for question selection."""
    await db.execute("""
        REFRESH MATERIALIZED VIEW CONCURRENTLY question_selection_index
    """)
```

---

## 7. Complete Integration Example

### Main Application Entry Point

```python
import asyncio
from dotenv import load_dotenv
import os
from prefect_dbt.cli import DbtShellTask
from openai import AsyncOpenAI
from prefect import flow, get_run_logger
import logging

load_dotenv()

# Configuration
CONFIG = {
    "telegram_bot_token": os.getenv("TELEGRAM_BOT_TOKEN"),
    "openai_api_key": os.getenv("OPENAI_API_KEY"),
    "prefect_api_url": os.getenv("PREFECT_API_URL", "http://localhost:4200"),
    "database_url": os.getenv("DATABASE_URL"),
    "webhook_url": os.getenv("WEBHOOK_URL"),
}

async def main():
    """Main entry point - initializes and runs the system."""
    
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    
    # Initialize database connection pool
    repo = QuizRepository(CONFIG["database_url"])
    await repo.initialize()
    logger.info("✅ Database initialized")
    
    # Initialize OpenAI client
    openai_client = AsyncOpenAI(api_key=CONFIG["openai_api_key"])
    
    # Initialize question generator
    question_generator = QuestionGenerator(openai_client, repo)
    
    # Initialize Telegram bot
    telegram_bot = QuizTelegramBot(
        bot_token=CONFIG["telegram_bot_token"],
        prefect_api_url=CONFIG["prefect_api_url"],
        webhook_url=CONFIG["webhook_url"]
    )
    await telegram_bot.setup_handlers()
    
    # Inject dependencies into Prefect tasks
    # (In practice, use Prefect's dependency injection or custom task factory)
    
    # Start webhook server
    logger.info("🚀 Starting quiz system...")
    await telegram_bot.start_webhook(port=8080)
    
    # Run forever (or until interrupted)
    try:
        await asyncio.Event().wait()
    except KeyboardInterrupt:
        logger.info("🛑 Shutting down...")
    finally:
        await telegram_bot.shutdown()
        await repo.close()


@flow(name="manual-quiz-test")
async def test_quiz_flow(user_id: str):
    """
    Manual test flow for development.
    
    Usage:
        python -c "import asyncio; from main import test_quiz_flow; asyncio.run(test_quiz_flow('123456'))"
    """
    logger = get_run_logger()
    
    # Generate a test question
    from quiz_generator import QuestionGenerator, DifficultyLevel, TopicCategory
    from openai import AsyncOpenAI
    from repository import QuizRepository
    
    openai_client = AsyncOpenAI(api_key=CONFIG["openai_api_key"])
    repo = QuizRepository(CONFIG["database_url"])
    await repo.initialize()
    
    gen = QuestionGenerator(openai_client, repo)
    
    question = await gen.generate_question(
        difficulty=DifficultyLevel.INTERMEDIATE,
        excluded_question_ids=[],
        preferred_topics=[TopicCategory.SQL_PERFORMANCE]
    )
    
    logger.info(f"Generated question: {question['question_text']}")
    logger.info(f"Options: {question['options']}")
    logger.info(f"Correct: {question['correct_option']}")
    logger.info(f"Explanation: {question['explanation']}")
    
    await repo.close()
    
    return question


if __name__ == "__main__":
    # Choose mode based on environment variable
    mode = os.getenv("QUIZ_MODE", "production")
    
    if mode == "test":
        # Run test flow
        asyncio.run(test_quiz_flow("123456"))
    else:
        # Run production webhook server
        asyncio.run(main())
```

### Environment Variables (.env)

```bash
# Telegram
TELEGRAM_BOT_TOKEN=your_bot_token_here

# OpenAI
OPENAI_API_KEY=your_openai_api_key

# Prefect
PREFECT_API_URL=http://localhost:4200
PREFECT_API_KEY=your_prefect_api_key

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/quiz_db

# Webhook
WEBHOOK_URL=https://your-domain.com

# Mode
QUIZ_MODE=production  # or "test"
```

### Docker Compose (Development)

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: quiz_user
      POSTGRES_PASSWORD: quiz_password
      POSTGRES_DB: quiz_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./schema.sql:/docker-entrypoint-initdb.d/schema.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U quiz_user"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  prefect-server:
    image: prefecthq/prefect:2.14-latest
    command: prefect server start
    environment:
      PREFECT_API_URL: http://localhost:4200/api
      PREFECT_UI_API_URL: http://localhost:4200/api
    ports:
      - "4200:4200"
    volumes:
      - prefect_data:/root/.prefect

  quiz-bot:
    build: .
    environment:
      - DATABASE_URL=postgresql://quiz_user:quiz_password@postgres:5432/quiz_db
      - TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - PREFECT_API_URL=http://prefect-server:4200
      - WEBHOOK_URL=${WEBHOOK_URL}
    depends_on:
      - postgres
      - redis
      - prefect-server
    ports:
      - "8080:8080"

volumes:
  postgres_data:
  redis_data:
  prefect_data:
```

---

## 8. Testing Strategy

### Unit Tests

```python
import pytest
from quiz_generator import DifficultyLevel, DifficultyAdapter
from datetime import date, timedelta

class TestDifficultyAdaptation:
    
    def test_correct_answer_increases_consecutive(self):
        adapter = DifficultyAdapter(None)
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=True,
            current_difficulty=DifficultyLevel.INTERMEDIATE,
            current_streak=5,
            consecutive_correct=2
        )
        
        assert new_streak == 6
        assert new_consec == 3
        assert new_diff == DifficultyLevel.INTERMEDIATE  # Not enough for promotion
    
    def test_three_consecutive_correct_promotes(self):
        adapter = DifficultyAdapter(None)
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=True,
            current_difficulty=DifficultyLevel.INTERMEDIATE,
            current_streak=5,
            consecutive_correct=2  # This makes it 3
        )
        
        assert new_diff == DifficultyLevel.ADVANCED
        assert new_consec == 0  # Reset after promotion
    
    def test_incorrect_resets_streak(self):
        adapter = DifficultyAdapter(None)
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=False,
            current_difficulty=DifficultyLevel.ADVANCED,
            current_streak=10,
            consecutive_correct=5
        )
        
        assert new_streak == 0
        assert new_consec == 0
        assert new_diff == DifficultyLevel.INTERMEDIATE  # Demoted
    
    def test_day_skipped_resets_streak(self):
        adapter = DifficultyAdapter(None)
        last_date = date.today() - timedelta(days=2)
        
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=True,
            current_difficulty=DifficultyLevel.INTERMEDIATE,
            current_streak=10,
            consecutive_correct=2,
            last_answer_date=last_date
        )
        
        assert new_streak == 0
        assert new_consec == 0
        assert new_diff == DifficultyLevel.BEGINNER  # Reset to beginner
    
    def test_expert_no_promotion(self):
        adapter = DifficultyAdapter(None)
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=True,
            current_difficulty=DifficultyLevel.EXPERT,
            current_streak=5,
            consecutive_correct=3
        )
        
        assert new_diff == DifficultyLevel.EXPERT  # Stays at expert
        assert new_consec == 0  # Reset counter
    
    def test_beginner_no_demotion(self):
        adapter = DifficultyAdapter(None)
        new_diff, new_streak, new_consec = adapter.calculate_adaptation(
            is_correct=False,
            current_difficulty=DifficultyLevel.BEGINNER,
            current_streak=2,
            consecutive_correct=1
        )
        
        assert new_diff == DifficultyLevel.BEGINNER  # Stays at beginner
        assert new_streak == 0
        assert new_consec == 0


@pytest.mark.asyncio
class TestQuestionGeneration:
    
    async def test_static_question_retrieval(self):
        from quiz_generator import QuestionGenerator
        from openai import AsyncOpenAI
        from unittest.mock import AsyncMock, MagicMock
        
        # Mock OpenAI client
        mock_client = MagicMock(spec=AsyncOpenAI)
        mock_db = MagicMock()
        
        gen = QuestionGenerator(mock_client, mock_db)
        question = gen._get_static_question(
            difficulty=DifficultyLevel.INTERMEDIATE,
            excluded_ids=[],
            preferred_topics=[TopicCategory.SQL_PERFORMANCE]
        )
        
        assert question is not None
        assert len(question["options"]) == 4
        assert "explanation" in question
    
    async def test_question_exclusion(self):
        # Test that seen questions are excluded
        pass
    
    async def test_llm_fallback_to_static(self):
        # Test that LLM failure falls back to static bank
        pass
```

### Integration Tests

```python
import pytest
import asyncpg
from repository import QuizRepository

@pytest.mark.asyncio
async def test_full_quiz_flow(db_pool: asyncpg.Pool):
    """
    End-to-end test: generate question → send → answer → validate → update state
    """
    repo = QuizRepository("postgresql://test:test@localhost/test_db")
    await repo.initialize()
    
    # Setup: Create test user
    await repo.create_user_if_not_exists("test_user_123", "testuser")
    
    # Get initial state
    state = await repo.get_user_state("test_user_123")
    assert state["current_difficulty"] == 2  # Default intermediate
    
    # Generate question
    question = await repo.get_next_adaptive_question("test_user_123", 2)
    assert question is not None
    
    # Persist question
    q_id = await repo.persist_question("test_user_123", question["question_id"], 12345, 2)
    assert q_id > 0
    
    # Store answer
    await repo.store_answer("test_user_123", question["question_id"], 12345, question["options"][0])
    
    # Validate answer
    is_correct = question["correct_option"] == question["options"][0]
    
    # Update state
    new_diff = int(state["current_difficulty"]) + (1 if is_correct else -1)
    await repo.update_user_state("test_user_123", new_diff, state["current_streak"] + (1 if is_correct else 0), 0)
    
    # Verify state change
    updated_state = await repo.get_user_state("test_user_123")
    assert updated_state["current_difficulty"] == new_diff
    
    # Cleanup
    await repo.close()
```

---

## 9. Monitoring and Observability

### Prefect Artifacts

```python
from prefect import flow, get_run_logger
from prefect.artifacts import (
    create_markdown_artifact,
    create_table_artifact,
    create_link_artifact
)

async def log_quiz_metrics(
    user_id: str,
    question_id: str,
    is_correct: bool,
    time_taken: int
):
    """Create Prefect artifacts for observability."""
    
    # Question log
    question_log = f"""
    ## Question Delivered
    
    - **User**: {user_id}
    - **Question ID**: {question_id}
    - **Status**: {"✅ Correct" if is_correct else "❌ Incorrect"}
    - **Time Taken**: {time_taken} seconds
    - **Timestamp**: {datetime.utcnow().isoformat()}
    """
    await create_markdown_artifact(
        markdown=question_log,
        name=f"Question-{question_id}"
    )
    
    # Daily summary table
    daily_data = [
        ["User", "Difficulty", "Streak", "Accuracy"],
        [user_id, difficulty, streak, f"{accuracy}%"]
    ]
    await create_table_artifact(
        table=daily_data,
        name="Daily Quiz Summary"
    )
```

### PostgreSQL Monitoring Queries

```sql
-- Question delivery success rate
SELECT 
    DATE(sent_at) as date,
    COUNT(*) as sent,
    COUNT(answered_at) as answered,
    ROUND(100.0 * COUNT(answered_at) / COUNT(*), 2) as response_rate
FROM user_questions
GROUP BY DATE(sent_at)
ORDER BY date DESC;

-- Difficulty distribution
SELECT 
    current_difficulty,
    COUNT(*) as user_count,
    ROUND(AVG(current_streak), 2) as avg_streak
FROM users
WHERE opt_in_daily_quiz = TRUE
GROUP BY current_difficulty;

-- Topic performance
SELECT 
    topic,
    SUM(questions_attempted) as total_attempts,
    SUM(questions_correct) as total_correct,
    ROUND(100.0 * SUM(questions_correct) / SUM(questions_attempted), 2) as accuracy
FROM topic_performance
GROUP BY topic
ORDER BY total_attempts DESC;
```

---

## 10. Deployment Checklist

- [ ] PostgreSQL schema deployed and migrations set up (Alembic)
- [ ] Static question bank populated (minimum 10 questions per difficulty/topic)
- [ ] Telegram bot token configured and webhook set
- [ ] Prefect server deployed (Cloud or self-hosted)
- [ ] OpenAI API key configured
- [ ] Daily quiz flow deployed with schedule (10:00 UTC)
- [ ] Answer webhook deployed and configured in Telegram
- [ ] Database connection pooling configured (pgBouncer if needed)
- [ ] Redis cache configured (optional, for performance)
- [ ] Monitoring dashboards created (Grafana/CloudWatch)
- [ ] Alerting configured for failed question deliveries
- [ ] Backup strategy for PostgreSQL (daily snapshots, WAL archiving)

---

## Summary

This architecture delivers a production-ready daily adaptive quiz system with:

1. **Prefect Orchestration**: Scheduled daily flows + webhook-triggered answer processing
2. **Adaptive Difficulty**: Gradual progression based on consecutive correct/incorrect answers
3. **Streak Tracking**: Daily streaks with reset logic for incorrect answers or missed days
4. **Robust Persistence**: PostgreSQL for relational queries, state management, and analytics
5. **Telegram Integration**: Real-time question delivery with inline keyboard UI
6. **Observability**: Prefect artifacts, DB monitoring, and logging throughout
7. **Extensibility**: Easy to add new topics, difficulty levels, or question sources

The system is designed for horizontal scaling (connection pooling, Redis caching) and production reliability (retries, error handling, monitoring).
