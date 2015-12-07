module marty.hash;

import std.exception : assumeUnique;
import std.typecons : Nullable;

/**
  * A Hash object that is immutable with time travelling features.
  */
immutable class Hash(K, V) {
  public:
    alias _data this;
    alias Value = Nullable!V;

    /**
     * Initialize a hash with data from a standard hash
     */
    this(immutable(Value[K]) data) pure {
        _data = data;
        _previousVersion = null;
    }

    ///
    unittest {
      immutable data = ["foo": Nullable!V(1)];
      immutable subject = new immutable(Hash!(string, int))(data);
    }

    /**
     * Create a new hash with the passed in value set.
     * Returns: New updated hash object with value inserted.
     */
    auto insert(in K key, in V value) pure {
        immutable(Value[K]) newHash = [key: Value(value)];
        return new immutable(Hash!(K, V))(newHash, this);
    }

    ///
    unittest {
        immutable data = ["foo": Nullable!V(1)];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.insert("bar", 2);
    }

    /**
     * Fetch a value from the hash. Raise an error if the key does not exist
     * in the hash.
     */
    Value opIndex(in K key) pure @nogc {
        auto ptr = key in _data;
        return ptr ? *ptr : _previousVersion[key];
    }

    ///
    unittest {
        immutable data = ["foo": Nullable!V(1)];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.insert("bar", 2);
        assert(result["bar"] == 2);
        assert(result["foo"] == 1);
    }

    /**
     * Return the previous state of the hash.
     */
    auto rollBack() @nogc pure {
        return _previousVersion;
    }

    ///
    unittest {
        immutable data = ["foo": Nullable!V(1)];
        immutable subject = new immutable(Hash!(K, V))(data);
        auto result = subject.insert("foo", Nullable!V(2)).rollBack;
        assert(result["foo"] == 1);
    }

    /**
     * Returns an updated hash with a key value removed from the hash.
     */
    auto remove(K key) pure {
        Value value;
        immutable(Value[K]) newHash = [key: value];
        return new immutable(Hash!(K, V))(newHash, this);
    }

    ///
    unittest {
        immutable data = ["foo": Nullable!V(1)];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.remove("foo");
        assert(result["foo"].isNull);
    }

  private:
    Value[K] _data;
    Hash!(K, V) _previousVersion;

    this(immutable(Value[K]) data, immutable(Hash!(K, V)) previousVersion) pure {
        _data = data;
        _previousVersion = cast(immutable)previousVersion;
    }
}

unittest {
    alias Foo = immutable(Hash!(string, int));
}
