"""
Utility for checking the status of Databricks jobs.
"""
from utils.databricks_client import DatabricksClient

def check_databricks_job_status(client: DatabricksClient, job_id: str) -> str:
    """
    Check the status of a Databricks job.

    Args:
        client: The Databricks client to use for the API call
        job_id: The ID of the job to check

    Returns:
        String representing the status of the job's last run
    """
    try:
        job_status = client.get_job_status(job_id)

        if not job_status:
            return "UNKNOWN"

        # Extract the status from the job run
        status = job_status.state.life_cycle_state
        return status
    except Exception as e:
        print(f"Error checking job status: {str(e)}")
        return "ERROR"
