import requests


User = {0: {"username":"", "password":"", "payments": [""]}} # Users table
Settings = {0: {"processor": "sardine", "CLIENT_ID": "", "CLIENT_SECRET": ""}} # User Settings table
Payments = {"": {"type": "", "amount": "", "Status": "", "NotaID": "", "userId": 0}} # Payments table
Processors = {"sardine": {"payment_types": ["order.declined","order.processed","order.confirmed","order.expired","order.complete"],
                            "query_url": "",},
              "stripe": {"payment_types": ["succeeded", "pending", "failed"],
                           "query_url": "https://api.stripe.com/v1/charges",},
            }

user_id = 0 # Logged in user
user_settings = Settings.get(user_id=user_id) # Payment processor, processor API credentials, etc.

# Payment processor selection
processor = user_settings["processor"] # user_settings.processor # This is selected by the FinOps team based on their account settings
client_ID = user_settings["CLIENT_ID"]
client_Secret = user_settings["CLIENT_SECRET"]
api_url = user_settings["query_url"]
payments = requests.get(api_url, json={"client_ID": client_ID, "client_Secret": client_Secret})

def issue_nota(payment):
    print(payment)
    pass
def release_nota(payment):
    print(payment)
    pass
def clawback_nota(payment):
    print(payment)
    pass

def process_sardine(payments):
    for payment in payments:
        if Payments.get(payment["ID"]).processed:
            print("Payment already processed")
            continue

        # Issue Nota after order confirmed or order processed?
        if payment["eventType"] == "order.confirmed": # Payment is pending
            issue_nota(payment)
        elif payment["eventType"] == "order.processed": # Payment has been processed, waiting for withdrawal
            issue_nota(payment)
        elif payment["eventType"] == "order.complete": # Payment has settled
            release_nota(payment)

        elif payment["eventType"] == "order.expired":
            # Simple case, user doesn't make an order in time
            continue
        elif payment["eventType"] == "order.declined":
            # Is there a lag between order confirmed and order declined? How long is that period? Does it depend on business days?
            # If there is a considerable lag, the nota would be issued after order confirmation, then clawed back after order declined
            continue

def process_stripe(payments):
    for payment in payments:
        if Payments.get(payment["ID"]).processed:
            print("Payment already processed")
            continue
        if payment["status"] == "pending": # Payment has been processed, waiting for withdrawal
            issue_nota(payment)
        elif payment["status"] == "succeeded": # Payment has settled
            release_nota(payment)
        elif payment["status"] == "failed":
            clawback_nota(payment)

