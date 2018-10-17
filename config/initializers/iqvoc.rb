# encoding: UTF-8

# Copyright 2011-2013 innoQ Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
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

require 'iqvoc'
require 'iqvoc/version'

ActiveRecord::Base.send :include, DeepCloning

##### INSTANCE SETTINGS #####

# initialize non-dynamic settings below
# see lib/iqvoc.rb for the list of available setting

Rails.configuration.after_initialize do
  if Iqvoc::Concept.note_class_names.empty?
    raise(TypeError, 'note_class_names misconfiguration: must not be empty')
  end
end

unless Rails.env.test?
end

Iqvoc.default_rdf_namespace_helper_modules << IqvocModuleHelper

Iqvoc.export_path = Rails.root.join('public/export')
Iqvoc.upload_path = Rails.root.join('public/uploads')

Iqvoc.config.register_setting('languages.pref_labeling', ['en'])
Iqvoc.config.register_setting('languages.further_labelings.Labeling::SKOS::AltLabel', ['en'])
Iqvoc.config.register_setting('languages.notes', ['en'])
Iqvoc::Concept.broader_relation_class_name  = 'Concept::Relation::SKOS::Broader::Poly'

