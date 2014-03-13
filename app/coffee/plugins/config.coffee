# Copyright 2014 Andrey Antukh <niwi@niwi.be>
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


class ConfigService
    defaults: {
        host: "localhost:8000"
        scheme: "http"
        defaultLanguage: "en"
        debug: false
        notificationLevelOptions: {
            "all_owned_projects": "All events on my projects"
            "only_watching": "Only events for objects i watch"
            "only_assigned": "Only events for objects assigned to me"
            "only_owner": "Only events for objects owned by me"
            "no_events": "No events"
        }
        languageOptions: {
            "es": "Spanish"
            "en": "English"
        }
    }

    initialize: (localconfig) ->
        defaults = _.clone(@.defaults, true)
        @.config = _.merge(defaults, localconfig)

    get: (key, defaultValue=null) ->
        return @.config[key] || defaultValue

module = angular.module("gmConfig", [])
module.service("$gmConfig", ConfigService)
