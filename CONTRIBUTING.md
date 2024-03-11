Thanks for taking the plunge!

## Reporting Issues

* It's always good to start with a quick search for an existing issue to post on, or related issues for context, before opening a new issue
* Including minimal examples is greatly appreciated
* If it's a bug, or unexpected behavior, reproducing on the latest development version (`Pkg.checkout("SpineOpt")`) is a good check and can streamline the process, along with including the first two lines of output from `versioninfo()`

## Contributing

* Feel free to open, or comment on, an issue and solicit feedback early on, especially if you're unsure about aligning with design goals and direction, or if relevant historical comments are ambiguous
* When developing a new functionality or modifying an existing one, considering the following to work on (possibly in one pull request)
    + Add the new functionality or modifying an existing one
    + Pair the new functionality with tests, and bug fixes with tests that fail pre-fix. Increasing test coverage as you go is always nice
    + Update the documentation (seen implementation details in the documentation for some advanced features)
* Aim for atomic commits, if possible, e.g. `change 'foo' behavior like so` & `'bar' handles such and such corner case`, rather than `update 'foo' and 'bar'` & `fix typo` & `fix 'bar' better`
* Pull requests will be tested against release and development branches of Julia, so using `Pkg.test("SpineOpt")` as you develop can be helpful
* The style guidelines outlined below are not the personal style of most contributors, but for consistency throughout the project, we should adopt them
* If you'd like to join our monthly developer meetings, just send us a message (spine_info@vtt.fi)

## Style Guidelines

* Include spaces
    + After commas
    + Around operators: `=`, `<:`, comparison operators, and generally around others
    + But not after opening parentheses or before closing parentheses
* Use four spaces for indentation (test data files and Makefiles excepted)
* Don't leave trailing whitespace at the end of lines
* Don't go over the 119 per-line character limit
* Avoid squashing code blocks onto one line, e.g. `for foo in bar; baz += qux(foo); end`
* Don't explicitly parameterize types unless it's necessary
* Never leave things without type qualifications. Use an explicit `::Any`.
* Order method definitions from most specific to least specific type constraints

## Further questions
* For developers there is some additional information in the implementation details (e.g. how to write a constraint).
* You can talk to your fellow developers over gitter if the above is insufficient.
