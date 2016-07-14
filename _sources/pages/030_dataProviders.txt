Data Providers
==============

Data providers are the main interface with the library and most of your code will interact with data providers. They are a wrapper around an immutable model or models. They listen to any changes on their models and notify their delegate whenever something changes. There are two types of data providers: DataProvider and CollectionDataProvider.

DataProviders are backed by a DataModelManager. The initializer requires you pass in a DataModelManager, but you can simplify this API with an extension. See :doc:`040_setup` for more info.

DataProviders also offer the ability to pause updates. See :doc:`090_otherFeatures`.

DataProvider
------------

A DataProvider wraps a single model. It has simple accessor methods for setting and retrieving data. When setting data in the cache, it uses the ``modelIdentifer`` of the model (see :doc:`050_models`) as the cache key.

Whenever the model (or any child model of this model) is changed anywhere in the system, the DataProvider will update its data and call its delegate. If a multiple DataProviders contain a model with the same ``modelIdentifier``, they will be kept in sync with the same data.

CollectionDataProvider
----------------------

A CollectionDataProvider wraps an array of models. It has simple accessor methods for setting and retrieving data, but also has mutating methods to insert, append, remove and update elements.

Whenever you ``setData``, you can provide a ``cacheKey`` for the collection. This should be a string which uniquely identifies the collection and will be used to cache it. It also allows multiple collections to share the same data. So, if multiple collections have the same cacheKey, they will always be kept in sync. If you insert into one collection, Rocket Data will insert into all the other collections and notify their delegates. All these changes will be persisted to the cache (but it will only be called once since its the same collection).

CollectionDataProviders also offer class methods which can set, append, insert, remove and update data. These allow you to update collections even if you don't have a reference to the CollectionDataProvider. For instance, if you receive a push notification with new data, you could add this to a collection data provider with a certain cacheKey. If the collection is in memory, it will simply mutate the collection. If it is not in memory, it will load it from the cache, mutate it, then save it back to the cache.

==============================
CollectionDataProviderDelegate
==============================

When the CollectionDataProvider calls its delegate, it includes a CollectionChange object. This includes a list of the specific changes made to the collection. You can use this to run animations on your UITableView or UICollectionView.
