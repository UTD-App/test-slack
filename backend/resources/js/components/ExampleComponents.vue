<template>
    <div>{{ msg }} - {{ usersCount }}</div>
</template>
<script>
    export default{
    
        data(){
            return {
                msg: 'message',
                usersCount: 0,
            }
        },
        mounted(){
            console.log('Component mounted.');
            window.Echo.channel('trades')
            .listen('NewTrade', (e) => {
                console.log(e.trade[0][0]);
                this.msg = e.trade[0][0];
            });


            var url_string = window.location;
            var url = new URL(url_string);
            let room_id = url.searchParams.get("room_id");
            let channel = window.Echo.join(`room-${room_id}`);
            //console.log(channel);
            channel
                .here((e) => {
                    console.log("here: ",e);
                    this.usersCount = 10;
                })
                .joining((e) => {
                    console.log("joining: ",e);
                    this.usersCount = 11;
                })
                .leaving((e) => {
                    console.log("leaving: ",e);
                    this.usersCount = 12;
                })
                .error((e) => {
                    console.log("error: ",e);
                    this.usersCount = 1;
                });
        }
    }
</script>