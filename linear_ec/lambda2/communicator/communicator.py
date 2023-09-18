

class Communicator(object):

    def __init__(self, _storage):
        self.storage = _storage

    def reduce_batch(self, vector, **kwargs):
        """

        :param vector: merged tensor
        :param kwargs: other params
        :return:
        """
        return

    def reduce_epoch(self, vector, **kwargs):
        """

        :param vector: merged tensor
        :param kwargs: other params
        :return:
        """
        return

    def reduce_scatter_batch(self, vector, **kwargs):
        """

        :param vector: merged tensor
        :param kwargs: other params
        :return:
        """
        return

    def reduce_scatter_epoch(self, vector, **kwargs):
        """

        :param vector: merged tensor
        :param kwargs: other params
        :return:
        """
        return

    def async_reduce(self, vector, **kwargs):
        """

        :param vector: merged tensor
        :param kwargs: other params
        :return:
        """
