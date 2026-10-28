When "reverse drill" is turned off, everything works fine.

When "reverse drill" is turned on:

Show three columns in the (sub)topic view:

| Card      | Forward      | Reverse        |
|-----------|--------------|----------------|
| topic 1   | Learned 2h   | new            |
| topic 2   | Learned 2h   | new            |
| topic 4   | Learning 30m | new            |
| topic 5   | Learning 10m | new            |
| topic 6   | new          | new            |

Every card has a forward learning state and a reverse learning state.  If "reverse drlll" is turned off, the right-most column is deleted from the view.  If it is later turned back on, then it will return to the state above.

After practicing a while, we might see the situation below,  Note, that before card "topic 6" is put into the learning window, we have added the reverse cards from topics 1 and 2.  Once a card graduates to "learned", if it is a reverse side of topic 1 or 2 then topic 6 (forward) would enter the learning window, but if it is the forward side of topic 3 or 4 then the matching reverse side would enter the learning window.

| Card      | Forward      | Reverse        |
|-----------|--------------|----------------|
| topic 1   | Learned 2h   | Learning 30m   |
| topic 2   | Learned 2h   | Learning 40m   |
| topic 4   | Learning 30m | new            |
| topic 5   | Learning 10m | new            |
| topic 6   | new          | new            |

