# What is this?
A high-ish level interface for [Talker](http://talkerapp.com/)

## How do I use it?

``` javascript
var Client = require('talker-client')
  , client = new Client({ token: 'your token here' })
  , room = client.join('your room name here')

room.on('users', function(message) {
  console.log('users currently connected', message.users)
  message.users.forEach(function(user) {
    if (user.name  === 'paul.sweeney') { room.message('oh hai, Paul!') }
  })

  setTimeout(function() { room.leave() }, 3000)
})
```
