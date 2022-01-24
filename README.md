# SampledPublisher

The SampledPublisher samples the output of a publisher based on events from another
publisher.

## Usage 

## Demo

[rxmarbles/sample](https://rxmarbles.com/#sample)
![screenshot](marbles.png)

## Installation

### Package.swift

Edit the Package.swift file. Add the SampledPublisher as a dependency:
 
```
let package = Package(
    name: " ... ",
    products: [ ... ],
    dependencies: [
        .package(url: "https://github.com/berikv/SampledPublisher.git", from: "1.0.0") // here
    ],
    targets: [
        .target(
            name: " ... ",
            dependencies: [
                "SampledPublisher" // and here
            ]),
    ]
)
```

### For .xcodeproj projects

1. Open menu File > Add Packages...
2. Search for "https://github.com/berikv/SampledPublisher.git" and click Add Package.
3. Open your project file, select your target in "Targets".
4. Open Dependencies
5. Click the + sign
6. Add SampledPublisher
