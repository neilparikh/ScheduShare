ScheduShare
===========

An web app that allows event organizers communicate with attendees. Built for HackTheNorth 2014.

## How it works

1. An event organizer creates an itinerary, and populates it with their events. They receive a unique code which they share with the attendees.
2. The attendees text this code to ScheduShare’s phone number (hosted by Twilio). The number responds with the itinerary created the organizer in step 1.
3. The organizer decides to broadcast a notification to everyone. All attendees who sent a text in step 2 will recieve broadcast.
