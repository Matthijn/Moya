![Moya Logo](web/moya_logo_github.png)

You're a smart developer. You probably use [Alamofire](https://github.com/Alamofire/Alamofire) to abstract away access to
NSURLSession and all those nasty details you don't really care about. But then,
like lots of smart developers, you write ad hoc network abstraction layers. They
are probably called "APIManager" or "NetworkModel", and they always end in tears.

# This fork
The above is the story of Moya. But there is one thing that bugs me about it. That huge single enum for the service. Which grows and grows. Next to that, you’ll split the definition of a single REST endpoint up into four different parts within one file. 

Here is all the goodness of Moya, without the horrifying Enum. Instead you can use structs which has multiple benefits:

- You can easily divide your API definition accros multiple files
- All information regarding one single API Restpoint is contained within one place

*Plus*

- Automatic generating of the `parameters` in the request based on the structure of the struct using reflection
- Easy support for urls with formatting like: `/user/{userId}`

# Example

```
struct Register: TargetType, ReflectiveParameters {

	// These are the same as you would define in Moya, notice the missing baseURL
	let path = "/account/register"
	let method = Moya.Method.POST
	let sampleData = NSData()

	// These are properties not defined in the TargetType protocol and are automatically added to the parameters dictionary through reflection
	let username = String
	let password = String
}
```

Now, with the beauty of structs. You automatically get a constructor for instance variables who have not been defined at compile time: So this yields: `Register(username: "Foo", password: "TopSecret")`

This way you can make a request the same way as you would have with Moya (RxMoya example)

```
myService.request(
	Register(username: "Foo", password: "TopSecret")
).subscribeNext { (response) -> Void in
	print(Welcome to our service!)
}
```

You might have noticed there was no `parameters` instance variable defined. Since the struct is extended through the `ReflectiveParameters` protocol these are automatically generated for us. 

The parameters used in this request will be:

```
[
	"username": "foo",
	"password": "topSecret"
]
```

## Nested parameters
Sometimes you want to sent a nested dictionary, which is also easy. Just use structs within your definition struct:

```
// Define a struct to embed which should implement the NestedDictionary protocol (which is empty and is only used for reflection)
struct Twitter: NestedDictionary
{
	let oAuthToken: String
	let oAuthSecret: String
}

struct Authenticate: TargetType, ReflectiveParameters
{
	
	let path = "/authenticate"
	let method = Moya.Method.POST
	let sampleData = NSData()

	let twitter: Twitter	
	let device: String

}
```

Which will generate a dictionary structure similar to:

```
[
	"twitter": [
		"oAuthToken": "theToken",
		"oAuthSecret": "theSecret"
	],
	"device": "iPad"
]
```

## URL Formatting
This is something Moya currently lacks in but makes for prettier URL’s in your REST service.

Consider the following struct:

```
struct User: TargetType
{
	let path = "/user/{id}"
	let method = Moya.Method.GET
	let sampleData = NSData()

	let id: Int
}
```

Now there is search and replace on the bracketed parts of the url to determine the path to use for this request. Since `{id}` is written in this path. It will look up the instance variable `id` for this struct and use that value as the actual path. 

This way the request the path will be: `/user/1`. 

If you also use the `ReflectiveParameters` protocol instance variables used to build the url will not be send in the dictionary. So no duplicate data is sent. 

# BaseURL

The BaseURL is not part of the definition of the struct. To add the BaseURL to the request make your own endpoint like so:

```
func defaultEndpoint(target: TargetType) -> Endpoint
{
	return Endpoint(
		URL: self.targetUrl(target),
		sampleResponseClosure: {
			.NetworkResponse(200, target.sampleData)
		},
		method: target.method,
		parameters: target.parameters,
		parameterEncoding: .URL,
		httpHeaderFields: nil
	)
}

func targetUrl(target: TargetType) -> String
{
	return NSURL(string: "http://yourBaseUrl.com").URLByAppendingPathComponent(target.parsedPath).absoluteString
}
```

Which you can use when you create your service:

```
let provider = RxMoyaProvider(endpointClosure: self.defaultEndpoint)
```

# Podfile

```
pod 'Moya/RxSwift' :git => 'https://github.com/Matthijn/Moya'
```

