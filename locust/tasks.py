#!/usr/bin/env python

from locust import HttpUser, task


class OAPUser(HttpUser):
    @task
    def login(self):
        self.client.get('/test1')

    @task
    def post_metrics(self):
        self.client.get('/test2')
