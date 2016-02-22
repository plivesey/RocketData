Threading
=========

Rocket Data attempts to be highly asynchronous for any heavy operation. For full details on threads, make sure you read the docs in the code.

  1. Data Providers are not thread-safe and can only be used on the main thread.
  2. All CacheDelegate methods are run by default on a background thread. If your cache is not thread-safe, you should use a serial dispatch_queue to synchronize access.
  3. All Consistency Manager operations are run on background queues.
  4. All callbacks to the data providers are always on the main thread.
