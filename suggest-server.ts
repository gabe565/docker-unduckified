import { onRequestGet } from "./functions/suggest.ts";

Bun.serve({
	hostname: "127.0.0.1",
	port: 8081,
	fetch: (request) => onRequestGet({ request }),
});
