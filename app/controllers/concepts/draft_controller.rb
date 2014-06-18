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

class Concepts::DraftController < ConceptsController
  def index
    authorize! :read, Iqvoc::Concept.base_class

    scope = Iqvoc::Concept.base_class

    # only select unexpired concepts
    scope = scope.not_expired
    scope = scope.published_with_newer_versions

    # if params[:broader] is given, the action is handling the reversed tree
    root_id = params[:root]
    if root_id && root_id =~ /\d+/
      scope = scope.includes(:broader_relations, :narrower_relations).references(:relations)
      @concepts = scope.where(Concept::Relation::Base.arel_table[:target_id].eq(root_id))
    else
      @concepts = scope.tops.includes(:narrower_relations).references(:concepts)
    end

    # When in single query mode, AR handles ALL includes to be loaded by that
    # one query. We don't want that! So let's do it manually :-)
    ActiveRecord::Associations::Preloader.new.preload(@concepts,
        Iqvoc::Concept.base_class.default_includes + [:pref_labels])

    @concepts.to_a.sort! do |a, b|
      a.pref_label.to_s <=> b.pref_label.to_s
    end

    respond_to do |format|
      format.html
      format.json do # Treeview data
        concepts = @concepts.select { |c| can? :read, c }.map do |c|
          url = (c.published?) ? concept_path(id: c, format: :html) : concept_path(id: c, format: :html, published: 0)
          {
            id: c.id,
            url: url,
            text: CGI.escapeHTML(c.pref_label.to_s),
            hasChildren: (params[:broader] ? c.broader_relations.any? : c.narrower_relations.any?),
            additionalText: (" (#{c.additional_info})" if c.additional_info.present?),
            published: (c.published?) ? true : false
          }
        end
        render json: concepts
      end
    end
  end
end
