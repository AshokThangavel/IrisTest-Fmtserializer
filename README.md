# IrisTest-Fmtserializer

`IrisTest.Format.Writer` is a Serialization utility for InterSystems IRIS IrisTest class that generates **JSON** and **YAML** representations of UnitTest results.  
It complements the existing [`IrisTest-html`](https://openexchange.intersystems.com/package/IrisTest-html) package by providing structured, machine-readable formats for UnitTest reporting.

## Features

- Export UnitTest results for a specific `UnitTestId` to **JSON** or **YAML**.
- Include all test metadata: namespace, duration, datetime, suite, test case, and assertions.
- Handles multiple methods and assertions per test case.
- Ready to integrate with reporting pipelines or CI/CD tools.

## ⚙️ Installation

### Clone the Repository
```bash
git clone https://github.com/AshokThangavel/IrisTest-Fmtserializer.git
cd IrisTest-Fmtserializer
````

### Running the Application with Docker

Build and start the app using Docker Compose:

```bash
docker-compose up --build
```

### Stopping the Application

To stop and remove the running containers:

```bash
docker-compose down
```

## Usage

```objectscript
// Generate JSON for UnitTestId 37, filtered by status "failed"
Set jsonResult = ##class(IrisTest.Format.Serializer).GenerateJSON(37, "failed")
Write jsonResult ; returns %DAO object

// Generate YAML for UnitTestId 37
Set yamlResult = ##class(IrisTest.Format.Serializer).GenerateYAML(37, "all")
Write yamlResult ; returns stream object