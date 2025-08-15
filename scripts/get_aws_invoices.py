import boto3
from datetime import datetime, timedelta, date
from dateutil.relativedelta import relativedelta
import json

def get_costs():
    """
    Retrieves the estimated costs for the last 30 days from AWS Cost Explorer.
    """
    # Create a Boto3 client for Cost Explorer
    ce_client = boto3.client('ce')

    # Define the time period for the query
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)

    try:
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost']
        )
        
        # Print the cost for the period
        total_cost = response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount']
        print(f"Your total estimated cost for the last 30 days is: ${float(total_cost):.2f}")

    except Exception as e:
        print(f"An error occurred: {e}")


def get_monthly_invoice_ids(months_lookback=12):
    """
    Retrieves a list of monthly invoice IDs for the current AWS account.
    """
    # Create a client for the Invoicing service (part of Billing)
    invoicing_client = boto3.client('invoicing')

    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    first_day_of_month = today.replace(day=1)

    try:
        for i in range(months_lookback):
            # Get the current date and calculate the start and end dates for the query.
            end_date = first_day_of_month - relativedelta(months=i)
            start_date = end_date - relativedelta(months=1)
            # print(f"Retrieving invoice summaries from {start_date.strftime('%Y-%m-%d')} to {end_date.strftime('%Y-%m-%d')}...")

            response = invoicing_client.list_invoice_summaries(
                Selector={
                    'ResourceType': 'ACCOUNT_ID',
                    'Value': '396724649279'
                },
                Filter={
                    'TimeInterval': {
                        'StartDate': start_date,
                        'EndDate': end_date
                    }
                },
                MaxResults=100  # Adjust as needed
            )
            
            invoice_summaries = response.get('InvoiceSummaries', [])
            invoice_summaries

            if invoice_summaries:
                for invoice in invoice_summaries:
                    print(f" InvoiceID - {invoice['InvoiceId']} IssuedDate: {invoice['IssuedDate'].strftime('%B %d, %Y')} Amount: {invoice['BaseCurrencyAmount']['TotalAmount']}")
            else:
                print("No invoice summaries found for the specified time period.")
            
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    get_monthly_invoice_ids(months_lookback=122)