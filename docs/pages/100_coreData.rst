Core Data Comparison
====================

There is no tool which will solve every problem. For many use cases, we believe Rocket Data is a better option to Core Data because of the speed and stability guarantees as well as working with immutable instead of mutable models. However, Core Data is useful for other use cases, and it's important to consider the differences before you make a decision for your app.

Core Data is an incredibly powerful framework with many useful features. However, this power comes at the cost of complexity. Most developers see crashes in production related to Core Data which are hard to trace and track down. Often, these are because many parts of Core Data aren't thread-safe. Performance problems are also common, and time is usually required to trace down issues with tools. Rocket Data doesn't have every feature that Core Data does, but for most applications, these features aren't used. If you really need a full SQLite database with the full set of SQLite features, then Core Data is a great option. However, if you're application just wants to cache data you get from a server and keep models consistent, we like Rocket Data.

.. raw:: html

    <table border="1" cellpadding="5">
    <tr>
    <td><b>Topic</b></td>
    <td><b>Rocket Data</b></td>
    <td><b>Core Data</b></td>
    </tr>
    <tr>
    <td>Models</td>
    <td>Uses immutable models which are always stored in the RAM. They can be serialized to disk for caching. Because they are in RAM, lookup is always extremely fast.</td>
    <td>Models are mutable and represent the data base object itself. Reading fields effectively reads from the data and writes update the database. If you read or write on the main thread, it may block since it involves a disk read.</td>
    </tr>
    <tr>
    <td>Thread Safety</td>
    <td>Models are thread safe since they are immutable.</td>
    <td>Models are not thread safe and need to be refetched when traversing threads.</td>
    </tr>
    <tr>
    <td>Collections</td>
    <td>Collections are an object which is persisted. The ordering of this collection is preserved. It is trivial to store multiple collections of the same model type, and the index does not need to be stored on the model itself.</td>
    <td>Core Data uses predicates to define an ordered set of models. Therefore, the order of the models needs to be stored on the model itself. It is difficult to have multiple collections using the same model because you often need to include several index properties on the model and update them accordingly.</td>
    </tr>
    <tr>
    <td>Mutating Collections</td>
    <td>You must mutate a collection on a specific collection (either with a CollectionDataProvider or a cacheKey). Changes are propagated to other collections that share data.</td>
    <td>Predicates are always watching for when models should be added or removed from a collection. New models are automatically inserted if they fulfill the predicate. However, adding models doesn't work automatically and requires additional code to make work.</td>
    </tr>
    <tr>
    <td>Disk I/O</td>
    <td>Disk access is always done asynchronously on a background thread. All main thread operations only access RAM. Any CPU heavy operations are done on background threads too.</td>
    <td>There are many different models for CoreData setups, but most involve doing read I/O on the main thread and write I/O on a background thread. Even writes on a background thread sometimes need to use the main thread to synchronize across threads.</td>
    </tr>
    <tr>
    <td>Normalized Data and Relationships</td>
    <td>Uses denormalized data. Models are always kept in tree format. When you get access to a model, you get all of the models in the tree in memory. Circular references between models are not possible. This API allows for required fields on models.</td>
    <td>Uses normalized data. All the models are effectively flattened. In order for one model to reference another, relationships are used. Relationships are lazily loaded references to another model. This means circular relationships are possible (and common). However, it means that lookups are always optional. You must ensure that child models are not deleted while a parent is using it. Otherwise, this will lead to a crash.</td>
    </tr>
    <tr>
    <td>Performance</td>
    <td>Scales well to a large number of accessors, models and model types. The only limit that we currently see is the size of RAM on devices.</td>
    <td>Scales extremely well to large data sets (in the GB range), but scales very poorly to the number of accessors and model types. Facebook has documented this extensively and has found it difficult to scale CoreData for their flagship app. https://youtu.be/XhXC4SKOGfQ?t=666</td>
    </tr>
    <tr>
    <td>Eviction</td>
    <td>Since the cache implementation is flexible, you can pick a cache solution which implements an eviction strategy. This means you can stop worrying about the cache taking up too much space.</td>
    <td>Core Data offers no eviction policy, so this must be manually managed.</td>
    </tr>
    <tr>
    <td>Stability</td>
    <td>At LinkedIn, We've been using data providers and the Consistency Manager with immutable models in production for a while now, and have seen almost no crashes from this part of our code. Since models are immutable, it is easy to write readable and stable code and verify correctness.</td>
    <td>Core Data is notorious for being unstable and difficult to verify correctness. In production, most developers see crashes and performance issues which are extremely difficult to track down. Since everything is mutable, as applications get larger, it becomes harder and harder to verify correctness.</td>
    </tr>
    <td>Migrations</td>
    <td>If you use a simple key-value store for your cache, likely, migrations are not necessary. If old data cannot be parsed into a model, you can treat it as a cache miss and load from an external source.</td>
    <td>You need to write migration logic for Core Data every time you change the schema.</td>
    </tr>
    <tr>
    <td>Search</td>
    <td>Rocket Data offers no built in search capabilities. However, since the cache implementation is up to you, can can search your cache, then add data to a data provider.</td>
    <td>Core Data offers a powerful search API and can do any operations that SQLite offers.</td>
    </tr>
    </table>
