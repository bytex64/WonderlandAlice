#!/usr/bin/python
import hashlib
import json
import sys
import argparse
import time
from math import floor
from flow import Flow

import config

startTime = time.time()

f = open('chain.json')
chain = json.load(f)
f.close()

def choice(w, n):
    l = chain["relations"][str(w)]
    i = int(floor(n * len(l)))
    return chain["relations"][str(w)][i]

def calculate(hashstr):
    # Start with a word after a period.
    w = chain["wordlist"].index('.')

    v = ''
    caps = True
    for i in range(0, len(hashstr), 2):
        n = int(hashstr[i:i + 2], 16)
        wn = choice(w, n / 256.0)
        word = chain["wordlist"][wn]
        if caps:
            word = word[0].upper() + word[1:]
            caps = False
        if word in (',', '.', '!', '?', ';', ':'):
            if word in ('.', '!', '?'):
                caps = True
        else:
            v += ' '
        v += word
        w = wn

    return v.lstrip() + '.'

def hash(str):
    m = hashlib.new('sha256')
    m.update(str)
    return calculate(m.hexdigest())

backend = None
myAccountId = None

def start():
    global myAccountId, backend
    try:
        backend = Flow(config.username)
        print("Logged in as %s" % config.username)
    except Flow.FlowError as e:
        if str(e) == 'Unknown account':
            print("Account not found; attempting login")
            backend = Flow()
            try:
                backend.create_device(config.username, config.password)
                print("Logged in")
            except Flow.FlowError as e2:
                if str(e2) == 'blah':
                    print("Account appears to be non-existent; attempting to create")
                    backend.create_account(config.username, config.password)
                    backend.set_profile('profile', json.dumps({"displayName": config.displayname}))
                    print("Account created")
                else:
                    raise
        else:
            raise

    myAccountId = backend.account_id()

    @backend.message
    def process_message(notif_type, notif_data):
        regular_messages = notif_data["regularMessages"]
        for message in regular_messages:
            if message["creationTime"] / 1000 < startTime:
                continue

            try:
                otherdata = json.loads(message["otherData"])
            except ValueError:
                # Whoops, no otherdata, moving on...
                continue

            if myAccountId in otherdata["highlighted"]:
                sender = message["senderAccountId"]
                cid = message["channelId"]
                oid = backend.get_channel(cid)["orgId"]
                msg = message["text"]
                backend.send_message(oid, cid, hash(msg))

def main():
    start()

    parser = argparse.ArgumentParser(description='Markov Chain Bot')
    parser.add_argument('--join', type=str, help='A Team ID to join')

    args = parser.parse_args()

    if args.join:
        backend.new_org_join_request(args.join)
        print("Requested to join %s" % args.join)
        sys.exit(0)

    print("Ready")
    backend.process_notifications()

if __name__ == "__main__":
    main()
