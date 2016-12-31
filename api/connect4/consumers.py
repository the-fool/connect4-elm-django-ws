from django.http import HttpResponse
from channels.handler import AsgiHandler
from channels.sessions import channel_session, enforce_ordering
from channels import Group
from django.core.cache import cache

@enforce_ordering(slight=True)
@channel_session
def ws_connect(message, *args, **kwargs):
    room = 'game-{}'.format(kwargs.get('room', None))
    message.channel_session['room'] = room
    Group(room).add(message.reply_channel)

@enforce_ordering(slight=True)
@channel_session
def ws_disconnect(message):
    Group(message.channel_session['room']).discard(message.reply_channel)

@enforce_ordering(slight=True)
@channel_session
def ws_message(message):
    # ASGI WebSocket packet-received and send-packet message types
    # both have a "text" key for their textual data.
    val = int(message.content['text'])
    val = val + 1
    Group(message.channel_session['room']).send({
        'text':'{}'.format(val)
    })
