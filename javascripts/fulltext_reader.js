  /**
 */
function FulltextReader(baseURL){
  var _reader = new ChunkedFileReader(baseURL);

  this.getData = function(offset, size) {
    _reader.seek(offset);
    var block = _reader.read(size);
    return _reader.blockToString(block);
  }
  
  this.hitToRecordData = function(hit) {
    _reader.seek(hit["recordOffset"]);
    var block = _reader.read(4);
    var size = _reader.blockToNumber(block);
    _reader.seek(hit["recordOffset"]);
    return _reader.read(size);    
  }
  
  this.getPrimaryKey = function(block) {
    // Primary key is the second offset in the header, stored as a long
    return _reader.blockToNumber(block.slice(4,7));    
  }
  
  this.getFields = function(block) {
    // Header: 8 == total field data size, primary key
    var headerSize = 8;
    var footerSize = 5;
    var size = block.length;
    var index = 0;
    var fields = [];
    var fieldStart = headerSize;
    while (fieldStart <= size - (headerSize + footerSize)) {
      // Fields are structured: data size, data, \0
      fieldSize = _reader.blockToNumber(block.slice(fieldStart,(fieldStart+3)));
      fields[index++] = _reader.blockToString(block.slice((fieldStart+4),(fieldStart+4+fieldSize)));
      fieldStart += fieldSize + 5;
    }
    return fields;      
  }  
  
  this.rankOffsets = function(term, hits, weights, compareSize, page, perPage) {
    page = page || 1;
    perPage = perPage || 10;
    compareSize = compareSize || false;
    var scores = [];
    var current = hits.size();
    var size = term.length;
    var percentDiff = 1;
    while (current > 0) {
      var hit = hits.get(current-1);
      // Comparing the size of hit to term length gives the importance of the 
      // term to the field. In general this can be approximated just as well 
      // based on average length of the field. If you compare, it requires 
      // reading every hit and looking up a lot of shards.
      //
      // For example: if you search for "John" in the sample corpus, the 
      // highest ranked item is "Johnson Johnson." If you compare size though,
      // "Johns John" is the highest ranked item. 
      //
      // Eventually we may just store the fieldSize in with the suffixes.
      if (compareSize) {
        _reader.seek(hit["offset"]);
        while (true) { if (_reader.getc() == 0) break; }
        var textSize = _reader.pos() - hit["offset"];
        var diff = Math.abs(size - textSize);
        percentDiff = 1 - (diff / size);
      }
      // Each item in the scores array will have [offset, score]
      scores[hit["recordOffset"]] = scores[hit["recordOffset"]] || [hit["recordOffset"], 0];
      scores[hit["recordOffset"]][1] += (weights[hit["fieldId"]] * percentDiff) + current;
      current -= 1;
    }
    // Compact the array
    var offsets = [];
    for (var i=0; i<scores.length; i++) {
      if (scores[i]) offsets.push(scores[i]); 
    }
    // Sort the array by score (descending)
    offsets.sort(function(a,b){ return b[1] - a[1] });
    var blocks = []
    var start = ((page-1)*perPage);
    for (var i=start; i<start+perPage; i++) {
      if (i > offsets.length - 1) break;
      item = offsets[i];
      _reader.seek(item[0]);
      var size = _reader.blockToNumber(_reader.read(4));
      _reader.seek(item[0]);
      var block = _reader.read(size);
      blocks.push([this.getPrimaryKey(block), this.getFields(block), item[1]]);
    }
    return blocks;    
  }
}