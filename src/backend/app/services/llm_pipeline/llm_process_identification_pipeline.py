import os
from pydantic import BaseModel, Field
import psycopg2
from psycopg2.extras import DictCursor
from typing import List
from langchain.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
import tiktoken  # Import tiktoken for token counting
# from langchain.chat_models import init_chat_model
from langchain_openai import OpenAIEmbeddings

# Set your Azure OpenAI configurations using environment variables
#api_key = os.getenv("AZURE_OPENAI_API_KEY")
#api_base = os.getenv("AZURE_OPENAI_ENDPOINT")
api_version = "2024-02-15-preview"  # Update to the correct version
azure_embedding_deployment_name = "text-embedding-ada-002"
azure_llm_deployment_name = "gpt-4o-mini"
openai_api_key = os.getenv("OPENAI_API_KEY")

# --- Retrieve processes from PostgreSQL ---
def fetch_processes_from_db():
    """
    Fetch process names and descriptions from the PostgreSQL database.
    """
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        raise ValueError("DATABASE_URL environment variable is not set.")

    # Connect to the PostgreSQL database
    try:
        connection = psycopg2.connect(database_url)
        cursor = connection.cursor(cursor_factory=DictCursor)

        # Query to fetch process names and descriptions
        query = "SELECT name, description FROM iso_processes"
        cursor.execute(query)

        # Fetch all rows
        processes = cursor.fetchall()

        # Combine name and description for embeddings
        process_data = [
            {
                "name": row["name"],
                "description": row["description"],
                "combined": f"{row['name']}: {row['description']}"
            }
            for row in processes
        ]

        return process_data

    except Exception as e:
        print(f"Error fetching data from database: {e}")
        return []

    finally:
        if connection:
            cursor.close()
            connection.close()



# --- Initialize tiktoken encoder ---
encoder = tiktoken.get_encoding("cl100k_base")  # Standard encoding for GPT-4 models

# --- Define Pydantic models ---
class InputValidationModel(BaseModel):
    is_valid_responsible_for: bool = Field(..., description="Indicates whether the user input for 'responsible_for' is valid or nonsense.")
    is_valid_supporting: bool = Field(..., description="Indicates whether the user input for 'supporting' is valid or nonsense.")
    is_valid_designing: bool = Field(..., description="Indicates whether the user input for 'designing' is valid or nonsense.")
    message: str = Field(..., description="A message explaining the reason for the validity of the inputs.", min_length=5)

class LanguageDetectionModel(BaseModel):
    is_german: bool = Field(..., description="True if the detected language is German.")
    is_english: bool = Field(..., description="True if the detected language is English.")
    detected_language: str = Field(..., description="The name of the detected language (e.g., English, German).")

class TranslatedTasksModel(BaseModel):
    responsible_for: List[str] = Field(..., description="List of tasks under 'Responsible For'.")
    supporting: List[str] = Field(..., description="List of tasks under 'Supporting'.")
    designing: List[str] = Field(..., description="List of tasks under 'Designing'.")

class LanguageTranslationOutputModel(BaseModel):
    translated_tasks: TranslatedTasksModel = Field(
        ...,
        description="The translated tasks separated into categories: 'responsible_for', 'supporting', and 'designing'."
    )


class ProcessIdentificationOutput(BaseModel):
    processes: List[str] = Field(..., description="List of processes from the available processes that the user is involved in.")

class ISOProcessInvolvementModel(BaseModel):
    process_name: str = Field(..., description="The name of the ISO process.")
    involvement: str = Field(..., description="The user's involvement level in this process. One of 'Not performing', 'Responsible', 'Supporting', 'Designing'.")

class ISOProcessesInvolvementOutput(BaseModel):
    processes: List[ISOProcessInvolvementModel] = Field(..., description="List of ISO processes and the user's involvement level.")

class RoleSelectionModel(BaseModel):
    selected_role_id: int = Field(..., description="The ID of the most suitable Systems Engineering role (1-14).")
    selected_role_name: str = Field(..., description="The name of the selected role.")
    confidence: str = Field(..., description="Confidence level: 'High', 'Medium', or 'Low'.")
    reasoning: str = Field(..., description="Brief explanation (2-3 sentences) for why this role was selected based on the tasks and processes.", min_length=20)

# --- Function to check token count ---
def check_token_count(prompt):
    """
    Calculate the number of tokens in the given prompt and return it.
    """
    return len(encoder.encode(prompt))


# --- Function to initialize the LLM ---
def init_llm():
    """
    Initialize the OpenAI LLM using environment variables.
    """
    llm = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=openai_api_key,
        temperature=0
    )
    return llm

def init_creative_llm():
    """
    Initialize a more creative OpenAI LLM using environment variables.
    """
    llm_creative = ChatOpenAI(
        model="gpt-4o-mini",
        openai_api_key=openai_api_key,
        temperature=0.8
    )
    return llm_creative

# --- Create the validation prompt and chain ---
def create_validation_prompt():
    system_prompt = """
You are an expert at validating work tasks and responsibilities of Systems Engineers (responsible for, supporting and desgining).
You will determine if all three user inputs (responsible for, supporting and desgining) is valid and meaningful tasks or nonsense. 
Inputs such as "Not responsible for any tasks," "Not supporting any tasks," or "Not designing any tasks" or something similar are acceptable as valid user inputs
because not all users could be desgining something etc.
"""
    user_prompt = "{tasks}"

    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt)
        ]
    )

def create_validation_chain(llm):
    prompt = create_validation_prompt()
    structured_llm = llm.with_structured_output(InputValidationModel)
    return prompt | structured_llm

# --- Create the language detection prompt and chain ---
def create_language_detection_prompt():
    system_prompt = """
You are a language expert. Detect whether the following text is in English or German.
"""
    user_prompt = "{tasks}"

    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt)
        ]
    )

def create_language_detection_chain(llm):
    prompt = create_language_detection_prompt()
    structured_llm = llm.with_structured_output(LanguageDetectionModel)
    return prompt | structured_llm

# --- Create the translation prompt and chain ---
def create_translation_prompt():
    system_prompt = """
    You are a translation expert. Translate the following text from German to English while preserving the structure and category headings.
    """
    user_prompt = "{tasks}"

    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt)
        ]
    )

def create_translation_chain(llm):
    prompt = create_translation_prompt()
    structured_llm = llm.with_structured_output(LanguageTranslationOutputModel)
    return prompt | structured_llm

# --- Create the process identification prompt and chain ---
def create_process_identification_prompt(process_data):
    system_prompt = """
        You are an expert in ISO processes. Given the user's tasks and the list of available processes (with descriptions truncated to save tokens), identify which processes the user is likely performing.

        IMPORTANT: The typical target audience is mostly involved in the following processes:
        - Business or mission analysis process
        - Validation process
        - Stakeholder needs and requirements definition process
        - System requirements definition process
        - System architecture definition process
        - Design definition process
        - System analysis process
        - Implementation process
        - Integration process
        - Verification process
        - Transition process
        - Operation process
        - Maintenance process
        - Disposal process

        They are sometimes involved in these processes:
        - Project planning process
        - Project assessment and control process
        - Decision management process
        - Risk management process
        - Configuration management process
        - Information management process
        - Measurement process
        - Quality assurance process

        And rarely in these processes:
        - Acquisition process 
        - Supply process 
        - Life cycle model management process
        - Infrastructure management process
        - Portfolio management process
        - Human resource management process
        - Quality management process
        - Knowledge management process

        Please weigh your identification based on these likelihoods and provide a structured output as a list of processes. Remember these are only generally observed biases, it may not be not applicable to user under consideration.
        """
    user_prompt = """
        User Tasks:
        {user_tasks}

        Available Processes:
        {available_processes}
        """
    truncated_processes = "\n".join(
        [f"{process['name']}: {process['description'][:200]}..." for process in process_data]
    )
    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt.format(user_tasks="{user_tasks}", available_processes=truncated_processes))
        ]
    )



def create_process_identification_chain(llm, process_data):
    prompt = create_process_identification_prompt(process_data)
    structured_llm = llm.with_structured_output(ProcessIdentificationOutput)
    return prompt | structured_llm

# --- Create the reasoning prompt and chain ---
def create_reasoning_prompt():
    system_prompt = """
        You are an expert in ISO processes. Given the user's tasks and the retrieved ISO processes, determine the user's involvement level in each process.

        IMPORTANT: The user's tasks are organized into three categories that directly map to involvement levels:
        - Tasks under "Responsible For:" → Assign "Responsible" involvement level (user has primary ownership and accountability)
        - Tasks under "Supporting:" → Assign "Supporting" involvement level (user assists others or provides support)
        - Tasks under "Designing:" → Assign "Designing" involvement level (user defines, architects, or improves processes/systems)

        Process classification bias (general trends, but defer to task category mapping above):
        - The target audience is primarily involved in:
            Business or mission analysis, Validation, Stakeholder needs and requirements definition, System requirements definition, System architecture definition, Design definition, System analysis, Implementation, Integration, Verification, Transition, Operation, Maintenance, Disposal.
        - They sometimes perform:
            Project planning, Project assessment and control, Decision management, Risk management, Configuration management, Information management, Measurement, Quality assurance.
        - They rarely perform:
            Acquisition, Supply, Life cycle model management, Infrastructure management, Portfolio management, Human resource management, Quality management, Knowledge management.

        Involvement levels (in descending order of responsibility):
        - Designing: User defines, architects, or improves the process (highest level of ownership)
        - Responsible: User has primary ownership and accountability for executing the process
        - Supporting: User assists others or provides support for the process
        - Not performing: User does not perform this process

        CRITICAL RULES:
        1. Match each task to the most relevant ISO process based on the task description
        2. Assign the involvement level based on which category the task was listed under
        3. If the user provides ANY meaningful tasks (not "Not responsible for any tasks" or similar),
           you MUST identify at least ONE process with an involvement level higher than "Not performing"
        4. A single ISO process can only have ONE involvement level - use the HIGHEST level if multiple tasks map to the same process

        Examples:
        - "Defining system requirements" under "Responsible For:" → System requirements definition process with "Responsible" involvement
        - "Code reviews" under "Supporting:" → Verification process with "Supporting" involvement
        - "Designing software architecture" under "Designing:" → System architecture definition process with "Designing" involvement
        - "Testing support" under "Supporting:" → Verification process with "Supporting" involvement

        Provide a structured output as a list of dictionaries with 'process_name' and 'involvement'.
        """
    user_prompt = """
        User Tasks:
        {user_tasks}

        Retrieved ISO Processes:
        {retrieved_iso_processes}
        """
    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt)
        ]
    )



def create_reasoning_chain(llm):
    prompt = create_reasoning_prompt()
    structured_llm = llm.with_structured_output(ISOProcessesInvolvementOutput)
    return prompt | structured_llm

# --- Create the role selection prompt and chain ---
def create_role_selection_prompt():
    system_prompt = """
You are an expert Systems Engineering career advisor. Given a person's work tasks and the ISO processes they are involved in, select the most suitable Systems Engineering role from the 14 standard SE roles.

Available SE Roles:
1. Customer - Represents the party that orders or uses a service. Has influence on design/technical execution.
2. Customer Representative - Interface between customer and company. Voice for customer-relevant information.
3. Project Manager - Responsible for planning and coordination. Monitors resources (time, costs, personnel) and moderates conflicts.
4. System Engineer - Has overview from requirements to system decomposition. Responsible for integration planning and interfaces.
5. Specialist Developer - Develops in specialist areas (software, hardware, etc.). Realizes product based on specifications.
6. Production Planner/Coordinator - Prepares product realization and transfer to customer.
7. Production Employee - Assembly and manufacture. Integrates system components and verifies functionality.
8. Quality Engineer/Manager - Ensures quality standards are maintained. Analyzes customer complaints and identifies causes.
9. Verification and Validation (V&V) Operator - Covers system verification and validation. Ensures system is verifiable and validatable.
10. Service Technician - Installation, commissioning, training, maintenance, repairs, and after-sales at customer site.
11. Process and Policy Manager - Develops internal guidelines and controls compliance with policies and laws.
12. Internal Support - IT support, qualification support, SE support. Advisory and supporting role during development.
13. Innovation Management - Focuses on commercially successful implementation of products, services, and business models.
14. Management - Decision-makers, management/department heads. Keeps eye on company goals, visions, and values.

Instructions:
- Analyze the user's tasks and their involvement in ISO processes
- Match their responsibilities, support activities, and design work to the role that best fits
- Consider the depth and breadth of their technical involvement
- Select the SINGLE most appropriate role (1-14)
- Provide confidence level: High (very clear match), Medium (good match but some ambiguity), Low (best guess among options)
- Explain your reasoning in 2-3 sentences
"""
    user_prompt = """
User's Work Tasks:
{user_tasks}

ISO Processes Involvement:
{process_involvement}

Based on the above, which of the 14 Systems Engineering roles is the best match?
"""
    return ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("user", user_prompt)
        ]
    )

def create_role_selection_chain(llm):
    prompt = create_role_selection_prompt()
    structured_llm = llm.with_structured_output(RoleSelectionModel)
    return prompt | structured_llm

# --- Initialize the FAISS retriever ---
from langchain_openai import AzureOpenAIEmbeddings
from langchain_community.vectorstores import FAISS

openai_embeddings = OpenAIEmbeddings(
    openai_api_key=openai_api_key,
    model="text-embedding-ada-002"
)

# Use absolute path based on module location for Docker/deployment compatibility
# This file is at: src/backend/app/services/llm_pipeline/llm_process_identification_pipeline.py
# FAISS index is at: src/backend/app/faiss_index/
_current_dir = os.path.dirname(os.path.abspath(__file__))
_faiss_index_path = os.path.join(_current_dir, '..', '..', 'faiss_index')

vector_store = FAISS.load_local(
    _faiss_index_path,
    openai_embeddings,
    allow_dangerous_deserialization=True
)

retriever = vector_store.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 10}  # Set a higher k initially
)

# --- Helper function to format retrieved documents ---
def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

# --- Create the modified pipeline with token check ---
def create_pipeline():
    llm = init_llm()
    llm_creative = init_creative_llm()
    validation_chain = create_validation_chain(llm)
    language_detection_chain = create_language_detection_chain(llm)
    translation_chain = create_translation_chain(llm)
    #process_identification_chain = create_process_identification_chain(llm_creative)
    reasoning_chain = create_reasoning_chain(llm)
    role_selection_chain = create_role_selection_chain(llm)

    # Fetch process data from the database
    process_data = fetch_processes_from_db()
    if not process_data:
        raise ValueError("Failed to fetch process data from the database.")
    
    def process_tasks(user_tasks_dict: dict):
        tasks_text = "\n".join(
            ["Responsible For:"] + user_tasks_dict.get("responsible_for", []) +
            ["Supporting:"] + user_tasks_dict.get("supporting", []) +
            ["Designing:"] + user_tasks_dict.get("designing", [])
        )

        # Step 1: Language Detection
        language_detection_result = language_detection_chain.invoke({"tasks": tasks_text})
        print("Language detection result:", language_detection_result)

        # Step 2: Translation if necessary
        if language_detection_result.is_german:
            translation_result = translation_chain.invoke({"tasks": tasks_text})
            # Reassemble the translated tasks from the structured output into the expected text format.
            translated = translation_result.translated_tasks
            translated_tasks_text = (
                "Responsible For:\n" + "\n".join(translated.responsible_for) + "\n" +
                "Supporting:\n" + "\n".join(translated.supporting) + "\n" +
                "Designing:\n" + "\n".join(translated.designing)
            )
            print("Translated tasks:", translated_tasks_text)
        else:
            translated_tasks_text = tasks_text

        # Step 3: Validation
        validation_result = validation_chain.invoke({"tasks": translated_tasks_text})
        print("Validation result:",validation_result)
        if not (validation_result.is_valid_responsible_for and validation_result.is_valid_supporting and validation_result.is_valid_designing):
            return {
                "status": "invalid_tasks",
                "message": validation_result.message
            }

        # Step 4: Process Identification
        process_identification_prompt = create_process_identification_prompt(process_data)
        full_prompt_text = process_identification_prompt.format_prompt(
            user_tasks=tasks_text
        ).to_string()
        token_count = check_token_count(full_prompt_text)
        print(f"Token count for process identification: {token_count}")

        # Step 2: Skip LLM invocation if token count exceeds limit
        #if token_count > 3000:
         #   return "Token count exceeds the 3000-token limit for process identification."
        

        # Step 3: Invoke process identification chain
        process_identification_chain = create_process_identification_chain(llm_creative, process_data)
        process_identification_input = {"user_tasks": tasks_text}
        process_identification_result = process_identification_chain.invoke(process_identification_input)
        identified_processes = process_identification_result.processes
        print("Identified Processes:", identified_processes)

        if not identified_processes:
            return "No relevant processes identified based on the user's tasks."

        # Step 5: Use identified processes as retrieval query (FAISS SEMANTIC SEARCH)
        retrieval_query = " ".join(
            [
                f"{process['name']} {process['description'][:200]}"
                for process in process_data if process["name"].lower() in [p.lower() for p in identified_processes]
            ]
        )

        k = len(identified_processes) + 4  # Adjust k based on the number of identified processes
        print(f"Retrieval Query: {retrieval_query}, Number of Chunks to Retrieve: {k}")

        # Step 6: Retrieve relevant documents using FAISS
        retrieved_docs = retriever.get_relevant_documents(retrieval_query)
        retrieved_docs = retrieved_docs[:k]  # Ensure we only take the top k documents

        print("Retrieved docs:", retrieved_docs)
        if not retrieved_docs:
            return "No documents retrieved from the FAISS store."

        # Format the retrieved documents
        retrieved_iso_processes = format_docs(retrieved_docs)
        print("Retrieved iso processes:", retrieved_iso_processes)
        # Step 7: Token Count Check before the final LLM call
        # Retrieve the reasoning prompt separately
        reasoning_prompt = create_reasoning_prompt()
        # Prepare the prompt that will be sent to the reasoning chain
        reasoning_prompt_text = reasoning_prompt.format_prompt(
            user_tasks=translated_tasks_text,
            retrieved_iso_processes=retrieved_iso_processes
        ).to_string()

        # Calculate the number of tokens in the prompt
        num_tokens = len(encoder.encode(reasoning_prompt_text))
        print(f"Number of tokens in the prompt: {num_tokens}")

        # If the token count exceeds 6000, adjust the retrieved chunks
        max_tokens = 6000
        if num_tokens > max_tokens:
            print("Token count exceeds the limit. Adjusting retrieved documents.")
            # Strategy: Reduce the number of retrieved documents
            while num_tokens > max_tokens and len(retrieved_docs) > 1:
                retrieved_docs = retrieved_docs[:-1]  # Remove the last document
                retrieved_iso_processes = format_docs(retrieved_docs)
                reasoning_prompt_text = reasoning_prompt.format_prompt(
                    user_tasks=translated_tasks_text,
                    retrieved_iso_processes=retrieved_iso_processes
                ).to_string()
                num_tokens = len(encoder.encode(reasoning_prompt_text))
                print(f"Adjusted number of tokens: {num_tokens}")

            if num_tokens > max_tokens:
                # If still too long, summarize the retrieved documents
                print("Even after adjusting, token count is too high. Summarizing retrieved documents.")
                summary_length = int(len(retrieved_iso_processes) * (max_tokens / num_tokens))
                retrieved_iso_processes = retrieved_iso_processes[:summary_length]
                reasoning_prompt_text = reasoning_prompt.format_prompt(
                    user_tasks=translated_tasks_text,
                    retrieved_iso_processes=retrieved_iso_processes
                ).to_string()
                num_tokens = len(encoder.encode(reasoning_prompt_text))
                print(f"Final adjusted number of tokens: {num_tokens}")

        # Step 8: Run the reasoning chain with adjusted prompt
        reasoning_input = {
            "user_tasks": translated_tasks_text,
            "retrieved_iso_processes": retrieved_iso_processes
        }
        reasoning_result = reasoning_chain.invoke(reasoning_input)
        print("Reasoning Result:", reasoning_result)

        # Step 9: NEW - LLM-based role selection
        # Format process involvement for role selection prompt
        process_involvement_text = "\n".join([
            f"- {p.process_name}: {p.involvement}"
            for p in reasoning_result.processes
            if p.involvement != 'Not performing'
        ])

        role_selection_input = {
            "user_tasks": translated_tasks_text,
            "process_involvement": process_involvement_text
        }

        llm_role_selection = role_selection_chain.invoke(role_selection_input)
        print("LLM Role Selection:", llm_role_selection)

        #return reasoning_result
        return {
            "status": "success",
            "result": reasoning_result,
            "llm_role_suggestion": {
                "role_id": llm_role_selection.selected_role_id,
                "role_name": llm_role_selection.selected_role_name,
                "confidence": llm_role_selection.confidence,
                "reasoning": llm_role_selection.reasoning
            }
        }

    return process_tasks

# --- Example usage ---
if __name__ == "__main__":
    # Create the modified pipeline
    pipeline = create_pipeline()

    # Define user tasks
    user_tasks = {
        "responsible_for": [
            "Defining system requirements for a new spacecraft mission.",
            "Overseeing the integration of propulsion and navigation subsystems.",
            "Validating the performance of thermal control systems in extreme conditions."
        ],
        "supporting": [
            "Collaborating with the software team to develop fault-tolerant algorithms.",
            "Assisting the project manager in creating a risk mitigation strategy.",
            "Providing technical insights during supplier selection for critical components."
        ],
        "designing": [
            "Designing a modular payload system to accommodate multiple instruments.",
            "Developing a model for the spacecraft's power distribution system.",
            "Creating a simulation environment for spacecraft docking procedures."
        ]
    }

    # Run the pipeline
    reasoning_result = pipeline(user_tasks)

    # Print the final output
    print("Final Output:", reasoning_result)
