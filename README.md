[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

# Endless Page View

Endless scrolling with full size cells.

EndlessPageView is meant to be an alternative to UICollectionView or UIScrollView to have endless pages/cells.

I created this because:
- Wanted to create a method that would pick a cell data based on the previous cell, e.g. related content.
- Didn’t want to insert and remove cells.
- Didn’t want to work with content size.
- Wanted to show next cell if data source did not return nil.

It works in paginated or non-paginated mode.

#### Dependencies

[Interpolate](https://github.com/marmelroy/Interpolate) - by [marmelroy](http://marmelroy.github.io/)
