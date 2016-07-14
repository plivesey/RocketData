Models
======

The models used in the library must be immutable and thread-safe. Thread safety is usually trivial if your models are immutable. All the models must either implement the Model or SimpleModel protocol. These protocols inherit from the ConsistencyManagerModel protocol.

Model vs SimpleModel
--------------------

SimpleModel is easier to implement since there are only two methods to implement, but they are less powerful. All immutable models are trees, and if you implement the Model protocol, the library will keep all subtrees consistent. So, if a child model needs updating, the library will replace it, regenerate a new person model, and update the DataProviders. The Model protocol takes more work to implement, but we would recommend it unless your models are very simple and you only need to keep the top level models consistent.

For a more detailed discussion on how child models are kept consistent, see https://linkedin.github.io/ConsistencyManager-iOS/pages/010_consistencyManager.html. However, you do not need to call the Consistency Manager directly because Rocket Data will do this automatically for you.

The Protocols
-------------

The Model protocol defines three main features:

  1. The ability to identify models as representing the same data. This is done by returning a globally unique identifier. If this identifier is the same, it means it represents the same data. This also defines a 'node' in the tree (see :doc:`010_rocketData`).
  2. Compare model for equality. Rocket Data needs to compare models to determine if models have actually changed. If a model hasn't changed, the library can short circuit.
  3. The ability to create new models by mapping on old models. The protocol allows the library to iterate over child nodes (and then recursively iterate over the whole tree) and then replace these models with updated models. This ability is not required by SimpleModel and therefore will not get consistency for child models.

Equality
--------

One important requirement for models is that models with the same id must be equal. You cannot have one model that has a child and another model with the same id which does not have this child. This will be considered an update to the Consistency Manager and one model will be updated.

Deletes
-------

Rocket Data supports deleting models. When a model is deleted, the map function in the Model protocol will return nil for a model. This means the model should remove this child model. If the child model is required, we recommend you cascade this delete and return nil for the current model. You do not need to worry about this for SimpleModels.

Examples
--------

These examples use an example of the models shown in :doc:`010_rocketData`.

=============
Message Model
=============

.. code-block:: c

  struct Message: Model, Equatable {
    let id: String
    let text: String
    let author: Person
    let image: Image?

    var modelIdentifier: String? {
      return "Message-\(id)"
    }

    func map(transform: (Model) -> Model?) -> Model? {
      guard let author = transform(self.author) as? Person else {
        // required field, so we will cascade the delete if person is deleted
        return nil
      }
      let image = transform(self.image)
      return Message(id: id, text: text, author: author, image: image)
    }

    func forEach(visit: (Model) -> Void) {
      visit(author)
      if let image = image {
        visit(image)
      }
    }
  }

  func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.id == rhs.id &&
      lhs.text == rhs.text &&
      lhs.author == rhs.author &&
      lhs.image == rhs.image
  }

============
Person Model
============

.. code-block:: c

  struct Person: Model, Equatable {
    let id: String
    let name: String

    var modelIdentifier: String? {
      return "Person-\(id)"
    }

    func map(transform: (Model) -> Model?) -> Model? {
      // Since the model has no children, there is nothing to map on
      return self
    }

    func forEach(visit: (Model) -> Void) {
    }
  }

  func ==(lhs: Person, rhs: Person) -> Bool {
    return lhs.id == rhs.id &&
      lhs.name == rhs.name
  }

====
JSON
====

You can use any networking protocol to represent your models. Here, we show how these models might be represented in JSON.

.. code-block:: json

  // Message model
  {
    "id": "12",
    "text": "Hey, how are you doing?",
    "author": {
      "id": "42",
      "username": "plivesey",
      "online": false
    },
    "image": {
      "path": "/static/images/img3.png",
      "width": 200
    }
  }

  // Contacts list
  {
    "contacts": [
      {
        "id": "42",
        "username": "plivesey",
        "online": false
      },
      {
        "id": "53",
        "username": "nsnyder",
        "online": true
      }
    ]
  }
