module marty.hash;

import std.exception : assumeUnique;

immutable class Hash(K, V) {
  public:
    alias _data this;

    this(immutable(V[K]) data) pure {
      _data = data;
      _previousVersion = null;
    }

    auto insert(in K key, in V value) pure {
      immutable(V[K]) newHash = [key: value];
      return new immutable(Hash!(K, V))(newHash, this);
    }

    V opIndex(in K key) pure {
      auto ptr = key in _data;
      return ptr ? *ptr : _previousVersion[key];
    }

  private:
    V[K] _data;
    Hash!(K, V) _previousVersion;

    this(immutable(V[K]) data, immutable(Hash!(K, V)) previousVersion) pure {
      _data = data;
      _previousVersion = cast(immutable)previousVersion;
    }
}

unittest {
  struct Foo {
    int bar;
  }

  alias Hsh = immutable(Hash!(string, Foo));

  auto foo = Foo(1);
  immutable rawHash = ["foo": foo];

  auto subject = new Hsh(rawHash);

  assert(subject["foo"] == foo);

  immutable newSubject = subject.insert("bar", foo);
  assert(newSubject != subject);
  assert(newSubject["bar"] == foo);
  assert(newSubject["foo"] == foo);
}
