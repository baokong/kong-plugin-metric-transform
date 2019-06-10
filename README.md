# Kong Metric Transformation

## Functionality
Added to a route with GET request and subsequent response format
```json
{
    data: {
        value: <number>,
        metric: <string>    // metric unit "dm", "cm", "km", etc.
    }
}
```
this plugin will convert the data to meters
{
    data: {
        value: <number>     // magnitude converted to meters
        metric: "m"
    }
}

## Error Handling


