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

#Derived from hierarchy_controller.rb
class Concepts::OpenactiveController < ConceptsController
  def index
    authorize! :read, Iqvoc::Concept.base_class

    scope = Iqvoc::Concept.base_class
    scope = scope.published

    # only select unexpired concepts
    # TODO decide handling of expired concepts for OA list
    scope = scope.not_expired

    @concepts = scope

    # When in single query mode, AR handles ALL includes to be loaded by that
    # one query. We don't want that! So let's do it manually :-)
    ActiveRecord::Associations::Preloader.new.preload(@concepts,
        Iqvoc::Concept.base_class.default_includes + [:pref_labels])

    @concepts.to_a.sort_by! {|c| c.pref_label }

    respond_to do |format|
      format.jsonld do
        concepts = @concepts.select { |c| can? :read, c }.map do |c|
          url = "https://openactive.io/activity-list/#{c.origin[1..-1]}"
          definition = c.notes_for_class(Note::SKOS::Definition).empty? ? "" : c.notes_for_class(Note::SKOS::Definition).first.value
          broader = []
          c.broader_relations.each do |rel|
            broader << "https://openactive.io/activity-list/#{rel.target.origin[1..-1]}"
          end
          narrower = []
          c.narrower_relations.each do |rel|
            narrower << "https://openactive.io/activity-list/#{rel.target.origin[1..-1]}"
          end
          concept = {
              id: url,
              identifier: c.origin[1..-1],
              type: "Concept",
              prefLabel: CGI.escapeHTML(c.pref_label.to_s)
          }
          concept[:broader] = broader if broader.any?
          concept[:narrower] = narrower if narrower.any?
          concept[:definition] = definition if definition != ""
          concept[:notation] = c.notations.first.value if c.notations.any?
          concept[:topConceptOf] = "https://openactive.io/activity-list" if c.top_term?
          if c.alt_labels.any?
            alt = []
            c.alt_labels.each do |l|
              alt << l.value
            end
            concept[:altLabel] = alt
          end
          concept
        end
        render json: {
            context: "https://openactive.io/",
            id: "https://openactive.io/activity-list",
            title: "OpenActive Activity List",
            description: "This document describes the OpenActive standard activity list.",
            type: "ConceptScheme",
            license: "https://creativecommons.org/licenses/by/4.0/",
            concepts: concepts
        }
      end

    end
  end
end
