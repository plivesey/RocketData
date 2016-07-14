A Case for Immutability
=======================

Functional programming has long proclaimed the benefits of using immutable models, but mobile clients traditionally have used mutable models. Swift has made writing with immutability much easier after introducing certain language features like structs and `let`. Immutable models have several advantages over mutable models:

  - Immutable models are thread-safe.
  - Debugging code is easier since there are fewer moving parts. You can easily isolate where model changes happen since there are so few places this can happen.
  - Your code naturally becomes more functional. Since your models can't have side effects anymore, when you read functions that take models as parameters, you know they won't change the model.
  - It leads to less UI code. Since you don't need to add listeners to every property in your model, you end up with less code. Instead, you only need to worry about one place the model can change.
  - Immutable models makes it easier to understand how model changes occur. Since it only happens in one place, you don't need to search the code for where your model was unexpectedly changed.
  - Immutability makes isolation possible. When using shared mutable models, changes you make locally can cause other changes which are unintended. With KVO, when one property changes, it may cause another to change and cascade, causing performance issues and situations which are difficult to debug.
