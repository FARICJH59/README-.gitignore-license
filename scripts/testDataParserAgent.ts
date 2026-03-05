import { DataParserAgent } from "../runtime/executor/dataParserAgent";

const agent = new DataParserAgent({ debug: true });

const sampleObject = { id: "123", status: "ok", attempts: 2 };
const sampleString = '{"id":"456","status":"error","reason":"invalid"}';

console.log("Parsing object input...");
const objectResult = agent.parseData(sampleObject);
console.log(objectResult);

console.log("Parsing JSON string...");
const stringResult = agent.parseData(sampleString);
console.log(stringResult);

console.log("Metrics snapshot:", agent.getMetrics());
