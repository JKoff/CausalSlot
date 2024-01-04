# CausalSlot

CausalSlot is a simple storage system that uses a causal consistency model, designed as a backing store for single-user multi-device applications.

_CausalSlot instance_: Process running CausalSlot, including a web administration interface (aka. localserver) and API (aka. remoteserver). Hosts any number of _slots_.

_Slot_: Blob, multiple concurrent versions may exist at a given time.

Simple:
- It compiles to a single binary.
- Data is persisted locally to sqlite3 files on a local filesystem.

Causal:
- Reads may return multiple versions of the value.
- Merging is left as an exercise to the application.
- Does not offer strong consistency.

TODO(jkoff): Link to client library.

## Installation

`$ shards build --release --no-debug` will produce a binary in bin/causalslot. Feel free to move this binary to a suitable location.

## Usage

Once you have compiled the binary, you can run it with the following command:

```$ ./bin/causalslot -d data -l "tcp://127.0.0.1:8080" -r "tls://127.0.0.1:8081?key=private.key&cert=certificate.cert&ca=ca.crt"``` where -d is the path where data should be persisted, -l is the address to bind to for the web administration interface and -r is the address to bind to for the API.

## Development

Unit tests:
```$ crystal spec```

Running the server locally:
```$ shards build && ./bin/causalslot -d data -l "tcp://127.0.0.1:8080" -r "tcp://127.0.0.1:8081"```

The sample client in client/ can then be used to interact with the server.

## Contributing

1. Fork it (<https://github.com/JKoff/causalslot/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jonathan Koff](https://github.com/JKoff) - creator and maintainer
