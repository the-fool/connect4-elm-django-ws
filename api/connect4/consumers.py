from django.http import HttpResponse
from channels.handler import AsgiHandler
from channels.sessions import channel_session, enforce_ordering
from channels import Group
from django.core.cache import cache


def get_open_game():
    """
    Get an open game id, and return the tuple :
    (need another player?, room id)
    """
    with cache.lock('LOCK'):
        open_game = cache.get('open')
        if open_game is not None:
            cache.expire('open', timeout=0)
            return (False, open_game)
        else:
            # TODO set game_id to 0 in read() method in AppConfig
            if cache.get('game_id') == None:
                cache.set('game_id', 0)
                cache.persist('game_id')
            open_game = cache.incr('game_id')
            cache.set('open', open_game)
            cache.persist('open')
            return (True, open_game)

@enforce_ordering(slight=True)
@channel_session
def ws_connect(message):
    new, room_number = get_open_game()
    room = str(room_number)
    message.channel_session['room'] = room
    Group(room).add(message.reply_channel)

    msg = "WAIT" if new else "START"
    Group(room).send({
        'text': msg
    })


@enforce_ordering(slight=True)
@channel_session
def ws_disconnect(message):
    Group(message.channel_session['room']).discard(message.reply_channel)

@enforce_ordering(slight=True)
@channel_session
def ws_message(message):
    # ASGI WebSocket packet-received and send-packet message types
    # both have a "text" key for their textual data.
    print(message.content['text'])

    Group(message.channel_session['room']).send({
        'text':'{}'.format(message.content['text'])
    })
