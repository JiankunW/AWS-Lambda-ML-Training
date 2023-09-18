from pymemcache.client import base

# Don't forget to run `memcached' before running this next line:
client = base.Client(('128.110.218.197', 11211))

# Once the client is instantiated, you can access the cache:
client.set('some_key_0', 'some value 0')
client.set('some_key_1', 'some value 1')

# Retrieve previously set data again:
print(client.get_multi(['some_key_0', 'some_key_1']))
client.delete_multi(['some_key_0', 'some_key_1'])
print(client.get_multi(['some_key_0', 'some_key_1']))