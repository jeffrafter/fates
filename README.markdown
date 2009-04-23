Copyright (C) 2006 Mauricio Fernandez <mfp@acm.org><br/>
Copyright (C) 2007 Jeff Rafter <jeff@jeffrafter.com> (additions, revisions)

Fate Search is based on FTSearch by Mauricio Fernandez which can be
found at http://www.eigenclass.org/

Fate Search uses a suffix-array, so if you look for e.g. "fa", it'll match
faq, fat, fat_entry, ..., making it equivalent to looking for "fa%". It does 
phrasal search naturally, if you're lookup for "big array", just enter it 
(without the quotes); with ferret-lookup.rb, you *have* to surround the phrase 
with quotes.


TRY IT OUT
----------

You can test things out using the rake tasks. Indexing:

<pre><code>
  $ rake fates:index
  (in /Users/njero/Projects/Web/fates)
  Removing the current index for contacts
  Preparing fields
  Reading contacts
  Indexing contacts
  Writing indexes
  Done
  Needed 0.015277 to remove the current indexes.
  Needed 1.611284 to read the contacts file.
  Needed 3.864082 to index the contacts.
  Needed 0.962226 to write the indexes.
  Total time: 6.453019
  Total records: 50000
</code></pre>

Searching:

<pre><code>
  $ rake fates:search QUERY='Smith'
  (in /Users/njero/Projects/Web/fates)
  Loading the index files
  Counting the number of hits
  Total hits: 4370 (0.000325)
  Looking up all matches
  Showing top 10 matches of 4370:
  "3499: Smith Dan"
  "37110: Smith Dan"
  "1193: Smith Dan"
  "45769: Smith Deb"
  "6702: Smith Deb"
  "48737: Smith Deb"
  "25339: Smith Den"
  "5754: Smith Den"
  "1029: Smith Den"
  "42762: Smith Eve"
  "32002: Smith Fae"
  ----
  Needed to load cache (0.002848)
  Needed to find all matches (0.000266)
  Needed to print matches (0.000598)
  Total time (0.00376)
</code></pre>

Searching with sorting and probabalistic ranking:

<pre><code>
  $ rake fates:search QUERY='Smith' SORT='y'
  (in /Users/njero/Projects/Web/fates)
  Loading the index files
  Counting the number of hits
  Total hits: 4370 (0.000385)
  Looking up all matches
  Showing all matches of 10:
  "3499: Smith Dan, (20004370.0)"
  "37110: Smith Dan, (20004369.0)"
  "1193: Smith Dan, (20004368.0)"
  "45769: Smith Deb, (20004367.0)"
  "6702: Smith Deb, (20004366.0)"
  "48737: Smith Deb, (20004365.0)"
  "25339: Smith Den, (20004364.0)"
  "5754: Smith Den, (20004363.0)"
  "1029: Smith Den, (20004362.0)"
  "42762: Smith Eve, (20004361.0)"
  ----
  Needed to load cache (0.003019)
  Needed to find all matches (0.000359)
  Needed to print matches (0.060236)
  Total time (0.063915)
</code></pre>  

If you apply sorting the results will be sorted and ranked but the printing 
(tree navigation) will take considerably longer. In the above example the print
time was 0.060236 versus 0.000598.

Note: currently delta indexes are not supported. Search allows you to 
look for names from the spec/samples/contacts.csv file. 

Gemify this with Jeweler. Consider some native extensions (based on the FTSearch
native extensions). In general lots of profiling was done around the sorting
and  initial indexing but as always you can still optimize.

I originally built ActiveRecord extensions for fates, but have removed them as
they would need additional work. As a sample though, you can still install the
library as a plugin:

<pre><code>script/plugin install git://github.com/jeffrafter/fates.git
</code></pre>  

Next you need to build the index. If you are just focused on names then you can 
cheat and reuse the existing search rake tasks (which already handle ranking and 
timing). Next you need to build the index. In the following I build an index for 
the PersonName model:

<pre><code>white_space = FateSearch::Analysis::WhitespaceAnalyzer.new 
analyzers = [white_space, white_space]
fragment = FateSearch::FragmentWriter.new(
  :path => "/tmp/index/fates/names-0000000", :analyzers => analyzers)
names = PersonName.find(:all)
names.each {|name| fragment.add(name.id, [name.given_name, name.family_name])}
fragment.finish!
</code></pre>  

Save this file in the lib folder of your rails application as "index.rb". Run 
the following (from your rails root). If you get an error about the directory 
not being empty then you will need to move the current indexes away.

<pre><code>script/runner lib/index.rb
</code></pre>  

You should now be able to run full text searches:

<pre><code>rake fates:search BASE_PATH='/tmp/index/fates/names' QUERY='banda'
</code></pre>  

Distribution and modification subject to the same terms as Ruby.
