Projections
===========

Usually, IDs must be globally unique. However, you can use the same ID for two different classes if you want to use projections. This feature is advanced and not particularly common.

For the full docs on this, please see: https://plivesey.github.io/ConsistencyManager/pages/055_projections.html.

However, there are a few additional things to note:

	1. This feature only works on ``Model`` objects (not ``SimpleModel``).
	2. You should implement ``mergeModel(model: Model)`` instead of ``mergeModel(model: ConsistencyManagerModel)``.
	3. Collections that hold different types are not automatically shared. You should not make two collections of different types share the same collection ID. (However, the models contained by collections can have different classes with the same ID. Only the collection IDs must be unique.)
