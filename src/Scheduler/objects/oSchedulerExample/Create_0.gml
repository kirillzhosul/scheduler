/// @description Initialisation.
// @author (с) 2022 Kirill Zhosul (@kirillzhosul)

// Counters.
counter_every_fast = 0;
counter_every_slow = 0;

// Slow counter, every 3 seconds.
every(room_speed * 3, function (){
	counter_every_slow++;
})

// Fast counter, every 1 second.
every(room_speed * 1, function (){
	counter_every_fast++;
})

// Delay message
after(room_speed * 2, function (){
	show_message_async("Message after 2 seconds!");
})

// Message after HTTP response.
http(http_get("https://google.com"), function(){
	show_message_async("Message after http request response!");
});