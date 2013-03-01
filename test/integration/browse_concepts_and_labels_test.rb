# encoding: UTF-8

# Copyright 2011 innoQ Deutschland GmbH
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

require File.join(File.expand_path(File.dirname(__FILE__)), '../integration_test_helper')

class BrowseConceptsAndLabelsTest < ActionDispatch::IntegrationTest

  setup do
    Labeling::Base.delete_all
    Concept::Base.delete_all

    Iqvoc::RDFAPI.parse_triples <<-EOT
      :tree rdf:type skos:Concept
      :tree skos:prefLabel "Tree"@en
      :tree skos:topConceptOf :scheme

      :baum rdf:type skos:Concept
      :baum skos:prefLabel "Baum"@de
      :baum skos:topConceptOf :scheme

      :forest rdf:type skos:Concept
      :forest skos:prefLabel "Forest"@en
      :forest skos:topConceptOf :scheme

      :forst rdf:type skos:Concept
      :forst skos:prefLabel "Forst"@en
      :forst skos:topConceptOf :scheme
    EOT
  end

  test 'selecting a concept in alphabetical view' do
    letter = 'T' # => Only the "Tree" should show up in the english version
    visit alphabetical_concepts_path(:lang => 'en', :prefix => letter, :format => :html)
    assert page.has_link?('Tree'), "Concept 'Tree' not found on alphabetical concepts list (prefix: #{letter})"
    assert !page.has_content?('Baum'), "Found concept 'Baum' on alphabetical concepts list (prefix: #{letter})"

    click_link_or_button('Tree')
    assert_equal concept_path('tree', :lang => 'en', :format => :html), URI.parse(current_url).path

    letter = 'F' # => Only the "Forest" should show up in the english version
    visit alphabetical_concepts_path(:lang => 'en', :prefix => letter, :format => :html)
    assert page.has_link?('Forest')
    assert !page.has_link?('Forst')
    assert !page.has_link?('Tree')
    assert !page.has_link?('Baum')
  end

  test 'showing a concept page' do
    visit concept_url('baum', :lang => 'en')
    assert page.has_content?('Baum'), "'Preferred label: Baum' missing in concepts#show"
    assert page.has_link?('Turtle'), 'RDF link missing in concepts#show'
    click_link_or_button('Turtle')
    assert page.has_content?(':baum a skos:Concept'), "':baum a skos:Concept' missing in turtle view"
  end

end
