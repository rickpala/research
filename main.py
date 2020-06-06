import json
import tweepy
import pprint
import requests


pp = pprint.PrettyPrinter(indent=2, stream=f)

consumer_key = "dRRhnzwiHlusb5KtRjIeAu8aR"
consumer_secret = "TvgaoWx5hFVTw0zZjQcqUXUqaCMyc8txvny4oOZr5it0AglADY"
access_token = "2477077929-COMHhJXBsUqe505cCgtHJqFLdtDlQuG0EWF9Z1K"
access_token_secret = "EBuNOtyfaNqnIqQHY9ku4HPaS5fSODuFW8c2bZzhO71ab"
api_url = "https://api.twitter.com/"
payload = {"status": "hi twitter, i tweeted this using code 🤓"}

def OAuth():
    try:
        auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
        auth.set_access_token(access_token, access_token_secret)
        return auth
    except Exception as e:
        return None

oauth = OAuth()
api = tweepy.API(oauth)

# Hello world tweet
# api.update_status("hi twitter, i tweeted this using code 🤓")

def search_with_tweepy(query):
    response = api.search(query)
    f = open('res.json', 'w')
    f.write(json.dumps(response[0]._json, indent=4))
    f.close()

def search_with_requests(query):
    search_api_url = api_url + "/1.1/search/tweets.json"
    r = requests.get(search_api_url, payload)
    print(json.dumps(r.json(), indent=2))


search_with_requests("Joe Rogan")
print("Done!")
