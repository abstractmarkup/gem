Abstract Markup Language
===
**What is Abstract Markup Language**

Abstract Markup Language is a robust and feature rich markup language designed to avoid repetition and promote clear, well-indented markup.

More information can be found at https://abstractmarkup.com/

## Installation
RubyGems is required (with Ruby 2.0.0+) to install the Abstract Markup Language gem:
```shell
sudo gem install aml
```

## Usage:
There are two ways to run Abstract Markup Language from the command-line; the first is to simply build a file:

```shell
aml --build path/to/file.aml
```

The other is to watch and build the file on changes: 

```shell
aml --watch path/to/file.aml
```

### Optional command-line arguments:

 - fileExtension
   - The file extension used for the build, default value of: _**html**_
     
     ```shell
     aml --build path/to/file.aml --fileExtension html
     ```

## Contributing:

Any and all comments are welcome; and more effort will be made to make it as simple as possible to contribute. There are two scripts in the _gem_ directory to build and test.

_*Please run these scripts from the root directory, not the gem directory itself.*_


**Building the Ruby Gem**

The build script will automatically:
  * Get the gem version number from aml.gemspec
  * Build the gem in the local directory
  * Install the gem to the system
  * Delete the gem in the local directory

```shell
./gem/build
```

**Testing the Ruby Gem**

The test script will automatically report a pass/fail status for existing tests in the tests directory.

```shell
./gem/test
```

