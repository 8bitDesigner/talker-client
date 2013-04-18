tls     = require("tls")
extend  = require("deep-extend")
Emitter = require("events").EventEmitter

module.exports = class TalkerClient extends Emitter
  constructor: (options = {}) ->
    @options = options
    @rooms = {}

  join: (room) ->
    connector = new Room(extend(@options, {room: room}))
    @rooms[room] = connector
    @bind(connector, room)
    return connector

  bind: (room, ns) ->
    events = ["connect", "message", "join", "users", "idle", "back", "leave"]

    # Repeat room events up to the client object
    repeater = (event, ns) => (payload) => @emit("#{ns}:#{event}", payload)
    room.on event, repeater(event, ns) for event in events

    # Toss the reference to the room object when you close it
    room.on "close", => delete @rooms[ns]

class Room extends Emitter
  constructor: (options = {}) ->
    host    = options.host or "talkerapp.com"
    port    = options.port or 8500
    timeout = options.timeout or 25000
    room    = options.room
    token   = options.token

    @socket = tls.connect port, host, {rejectUnauthorized: false}, =>
      @send("connect", {"room": room, "token": token})
      @emit "connect"
      @pinger = setInterval(@ping.bind(@), timeout)

    @socket.setEncoding("utf8")

    @socket.on "data", (data) =>
      parse = (line) =>
        message = if line is "" then null else JSON.parse(line)
        @emit message.type, message if message
      parse(line) for line in data.split("\n")

  ping: -> @send("ping")

  message: (content, to) ->
    payload =
      content: content
      to: to if to
    @send("message", payload)

  leave: ->
    @send("close")
    @emit("close")
    delete @pinger
    @socket.destroy()

  send: (type, message={}) ->
    payload = extend(message, {type: type})
    if @socket.readyState isnt "open"
      return @emit "error", "cannot send with readyState: #{@socket.readyState}"
    @socket.write JSON.stringify(payload), "utf8"
