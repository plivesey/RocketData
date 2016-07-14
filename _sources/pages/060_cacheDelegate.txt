Cache Delegate
==============

The cache delegate implements the cache for Rocket Data. You can use any cache you'd like, but the API is well suited for a key-value store. How you implement the delegate is up to you.

See CacheDelegate.swift for specifics on threading and how to implement this protocol.

Casting
-------

The methods in the CacheDelegate are generic with a parameter T: SimpleModel. Given a cacheKey, you should return an element of this class. However, you may not have an initializer for SimpleModel. Instead, you probably have an initializer for your own model superclass (or protocol). For instance:

.. code-block:: c

  class MyModelSuperclass {
    required init(data: Data) {
    }
  }

  class Message: MyModelSuperClass, Model {
    // Implementation here
  }

You can use the ParsingHelpers to assume that the model requested is a MyModelSuperclass. So, given Data from your cache, you can create a generic Model:

.. code-block:: c

  let (model, error): (T?, NSError?) = ParsingHelpers.parseModel { (aClass: MyModelSuperclass.Type) in
    // Note: here, it will create an instance of type T (e.g. Message or Person)
    return aClass.init()
  }

These functions in ParsingHelpers can be useful for returning generic models assuming a certain superclass or protocol.

Context Parameter
-----------------

Whenever you make a change to a DataProvider, you have the option of passing in a context parameter. This context parameter is then returned to the CacheDelegate. This context can be anything, and allows you to implement custom logic for caching or consistency. For instance, you may want to pass in a url as the context so you can cache your objects by url as well as by modelIdentifier.

Normalized vs Denormalized Data
-------------------------------

All the models used in Rocket Data are denormalized. They always have a tree structure. This is useful because it means that models are always available and you can verify that they will never change. However, when you want to cache the models, it's preferable to normalize the models and cache each node separately. This isn't a requirement to using this library, but your cache won't maintain full consistency unless you normalize your models.
