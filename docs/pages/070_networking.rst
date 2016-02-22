Networking
==========

Likely, you want to fetch data from the network in DataProviders. The library does not implement any networking features to keep the scope and API simple. However, you can easily add extensions to DataProviders to write generic networking methods.

Given a request class specific to your application (MyNetworkRequest) and a NetworkManager which returns a generic MyModelSuperClass, you could write this extension.

.. code-block:: c

  extension CollectionDataProvider where T: MyModelSuperClass {
    func fetchData(request: MyNetworkRequest,
                   cacheKey: String?,
                   fetchFromCache: Bool = true,
                   completion: (T?, NSError?) -> ()) {
      if fetchFromCache {
        fetchDataFromCache(cacheKey: cacheKey) { models, error in
          completion(models, error)
        }
      }

      NetworkManager.fetchCollection(request) { (data: [T]?, error) in
        if let data = data {
          self.setData(data, cacheKey: cacheKey)
        }
        completion(data, error)
      }
    }
  }

In this extension, we are fetching from the cache and network in parallel. Since we implement it as an extension, we can write custom logic here and any network stack. You can write a similar extension on DataProvider.

If the network returns before the cache, the cache data should be discarded. Rocket Data automatically handles this. If you setData while a cache request is in flight, it will discard the result of the cache.
