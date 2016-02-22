Other Features
==============

Context
-------

All mutating functions on the data providers have an optional context parameter. This context is then passed to the CacheDelegate and the Consistency Manager. Any DataProvider which is updated as a result of this mutation receives this context parameter. This is useful for correlating mutations with caches and updates. It is never read by the library, so you can pass anything you want here.

Pausing
-------

One advantage of immutable models is the ability to pause listening to updates. Even if a model should get updated, if the DataProvider is paused, it will not call its delegate and the data will still read the old model. Once the DataProvider is unpaused, it will be updated to the latest model (if there were any changes). This is useful if a view controller is not visible and you don't want to rerender it with model updates.

Batch Listening
---------------

Sometimes, you may want to batch listen to multiple DataProviders at once. This is useful if you have a view controller with multiple data providers and you only want one delegate callback even if multiple data providers change.

Logging
-------

If you make a mistake in setting up or using Rocket Data, it will throw an assertion. This will not crash in release builds and the library always makes a best effort to recover (usually by ignoring a change and reverting to a previous state). This assert is implemented in the Logger class. If you want to intercept this assert, you can implement the LoggerDelegate.

The Consistency Manager can make many changes while the application runs. If you want additional information for debugging purposes, you may want to register as the delegate of the ConsistencyManager owned by the DataModelManager. See https://linkedin.github.io/ConsistencyManager-iOS/pages/110_errorsAndDebugging.html for more information.
