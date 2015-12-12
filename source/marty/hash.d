module marty.hash;

import std.typecons : Nullable;
import std.algorithm : sort;
import std.algorithm.iteration : map, filter, uniq;
import std.array : array, assocArray;
import std.range : zip;

/**
 * A Hash object that is immutable with time travelling features.
 */
immutable class Hash(K, V) {
public:
    alias Value = Nullable!V;

    /**
     * Initialize a hash with data from a standard hash
     */
    this(immutable(V[K]) data) pure {
        Value[K] hash;
        foreach(K key, V value; data) {
            hash[key] = Value(value);
        }
        _data = cast(immutable)hash.dup;
        _previousVersion = null;
    }

    ///
    unittest {
        immutable data = ["foo": 1];
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
        immutable data = ["foo": V(1)];
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
        immutable data = ["foo": V(1)];
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
        immutable data = ["foo": 1];
        immutable subject = new immutable(Hash!(K, V))(data);
        auto result = subject.insert("foo", 2).rollBack;
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
        immutable data = ["foo": 1];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.remove("foo");
        assert(result["foo"].isNull);
    }

    /**
     * Returns all the keys in the hash which have a non null value.
     */
    K[] keys() pure {
        return allKeys.filter!(k => !this[k].isNull).array;
    }

    ///
    unittest {
        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data);
            assert(subject.keys[0] == "foo");
            assert(subject.keys.length == 1);
        }

        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data)
              .insert("bar", 2);
            assert(subject.keys[0] == "bar");
            assert(subject.keys[1] == "foo");
        }

        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data)
              .insert("bar", 2)
              .remove("bar");
            assert(subject.keys[0] == "foo");
            assert(subject.keys.length == 1);
        }

        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data)
              .insert("bar", 2)
              .remove("foo");
            assert(subject.keys[0] == "bar");
            assert(subject.keys.length == 1);
        }

        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data)
              .insert("foo", 2);
            assert(subject.keys[0] == "foo");
            assert(subject.keys.length == 1);
        }
    }

    /**
     * Returns an array of all the values in the hash.
     */
    V[] values() pure {
        return keys
            .map!(k => this[k].get)
            .array;
    }

    ///
    unittest {
        {
            immutable data = ["foo": 1];
            immutable subject = new immutable(Hash!(string, int))(data)
              .insert("bar", 2);
            assert(subject.values[0] == 2);
            assert(subject.values[1] == 1);
        }
    }

    /**
     * Makes foreach work on this class.
     */
    int opApply(int delegate(K key, V value) dg) {
        auto hash = zip(keys, values).assocArray;
        foreach(K key, V value; hash) {
            dg(key, value);
        }
        return 0;
    }

    ///
    unittest {
        immutable data = ["foo": 1];
        immutable base = new immutable(Hash!(string, int))(data);
        auto subject = base.insert("bar", 2);

        V[] values;
        K[] keys;

        foreach(K key, V value; subject) {
            values[values.length++] = value;
            keys[keys.length++] = key;
        }

        assert(values.length == 2);
        assert(keys.length == 2);
    }

    ///
    unittest {
        immutable data = ["foo": 1];
        immutable base = new immutable(Hash!(string, int))(data);
        auto subject = base.insert("bar", 2).insert("foo", 3);

        V[] values;
        K[] keys;

        foreach(K key, V value; subject) {
            values[values.length++] = value;
            keys[keys.length++] = key;
        }

        assert(values.length == 2);
        assert(keys.length == 2);
    }

    /**
     * Compacts the storage hash to speed up lookups.
     */
    auto compact() pure {
        Value[K] hash = zip(keys, values.map!(v => Value(v))).assocArray;
        immutable Value[K] newHash = cast(immutable)hash.dup;
        return new immutable(Hash!(K, V))(newHash, this);
    }

    ///
    unittest {
        immutable data = ["foo": 1];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.insert("bar", 2).compact;
        assert(result._data["foo"] == 1);
        assert(result["foo"] == 1);
        assert(result._data["bar"] == 2);
        assert(result["bar"] == 2);
    }

    /**
     * Purge the previous version from history.
     */
    auto purge() {
        V[K] hash = zip(keys, values).assocArray;
        immutable V[K] newHash = cast(immutable)hash.dup;
        return new immutable(Hash!(K, V))(newHash);
    }

    ///
    unittest {
        immutable data = ["foo": 1];
        immutable subject = new immutable(Hash!(string, int))(data);
        auto result = subject.insert("bar", 2).purge;
        assert(result._data["foo"] == 1);
        assert(result["foo"] == 1);
        assert(result._data["bar"] == 2);
        assert(result["bar"] == 2);

        assert(result._previousVersion is null);
    }

private:

    Value[K] _data;
    Hash!(K, V) _previousVersion;

    this(immutable(Value[K]) data, immutable(Hash!(K, V)) previousVersion) pure {
        _data = data;
        _previousVersion = cast(immutable)previousVersion;
    }

    /**
     * Returns an array of all the keys that have ever been set in the hash.
     */
    K[] allKeys() {
        if (_previousVersion) {
            return sort(_data.keys ~ _previousVersion.allKeys).uniq.array;
        }
        else {
            return _data.keys;
        }
    }
}

unittest {
    alias Foo = immutable(Hash!(string, int));
}
