Setup
=====

To setup the library in your app, you need to do a few steps:

  1. Implement your CacheDelegate
  2. Create your DataModelManager
  3. Make your models implement the Model or SimpleModel protocol
  4. (Optional) Add extensions to classes for a simpler API

Implement the CacheDelegate
---------------------------

Rocket Data allows you to specify your own cache implementation. You should create a class which implements the CacheDelegate protocol to hook up your cache to the library. See :doc:`060_cacheDelegate` for more information.

Create your DataModelManager
----------------------------

Applications can have multiple DataModelManagers, but in most cases, you'll just use one. The DataModelManager is the glue which connects the DataProviders with the cache and the Consistency Manager. The easiest way to do this is add a singleton in an extension. For example:

.. code-block:: c

  extension DataModelManager {
    static let sharedInstance = DataModelManager(cacheDelegate: MyCacheDelegate())
  }

Implement Model or SimpleModel
------------------------------

All the models you use must implement the Model or SimpleModel protocol. See :doc:`050_models` for more information.

Add Extensions to DataProviders for a simpler API
-------------------------------------------------

Since you now have a singleton DataModelManager, we recommend adding these extensions for a simpler API. They simply allow you to avoid passing in the DataModelManager every time. The original init is still available though if you want to use dependency injection.

.. code-block:: c

  extension DataProvider {
    convenience init() {
      self.init(dataModelManager: DataModelManager.sharedInstance)
    }
  }

  extension CollectionDataProvider {
    convenience init() {
      self.init(dataModelManager: DataModelManager.sharedInstance)
    }
  }

You can add similar extensions to any method which takes the DataModelManager as a parameter including the class methods of CollectionDataProvider and the BatchDataProviderListener methods.
