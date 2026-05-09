import os
import datetime
import logging
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.core.exceptions import AzureError

# Create the Function App
app = func.FunctionApp()

# Define environment variables
SUBSCRIPTION_ID = os.environ.get("AZURE_SUBSCRIPTION_ID")
RESOURCE_GROUP = os.environ.get("RESOURCE_GROUP")


@app.timer_trigger(schedule="0 */5 * * * *",
                   arg_name="myTimer",
                   run_on_startup=False,
                   use_monitor=True)
def stop_vms_timer(myTimer: func.TimerRequest) -> None:
    # Check if the timer is past due
    if myTimer.past_due:
        logging.warning("The timer function is running late!")

    logging.info(f"Azure Function executed at {datetime.datetime.utcnow()}")

    try:
        # Validate environment variables
        if not SUBSCRIPTION_ID or not RESOURCE_GROUP:
            logging.error("Missing required environment variables: AZURE_SUBSCRIPTION_ID or RESOURCE_GROUP")
            return

        # Authenticate using Managed Identity or Service Principal
        credential = DefaultAzureCredential()
        compute_client = ComputeManagementClient(credential, SUBSCRIPTION_ID)

        logging.info("Fetching virtual machines...")

        # Get all VMs in the resource group
        vms = list(compute_client.virtual_machines.list(RESOURCE_GROUP))
        logging.info(f"Found {len(vms)} VMs in resource group '{RESOURCE_GROUP}'")

        for vm in vms:
            vm_name = vm.name
            try:
                # Check current power state
                instance_view = compute_client.virtual_machines.instance_view(RESOURCE_GROUP, vm_name)
                power_state = next(
                    (status.code for status in instance_view.statuses if status.code.startswith('PowerState/')),
                    None
                )

                if power_state and "running" in power_state.lower():
                    logging.info(f"Stopping VM: {vm_name}")
                    stop_operation = compute_client.virtual_machines.begin_power_off(RESOURCE_GROUP, vm_name)
                    stop_operation.result()
                    logging.info(f"Successfully stopped VM: {vm_name}")
                else:
                    logging.info(f"VM {vm_name} is already stopped (current state: {power_state}). Skipping.")
            except AzureError as e:
                logging.error(f"Error processing VM {vm_name}: {str(e)}")
                continue

    except Exception as e:
        logging.error(f"Error in stop_vms_timer function: {str(e)}")
        raise

