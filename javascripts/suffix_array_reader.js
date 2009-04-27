/**
 */
function SuffixArrayReader(fulltextReader, shardSize, baseURL){
  var _fulltextReader = fulltextReader;
  var _shardSize = shardSize;
  var _baseURL = baseURL;
  var _cache = [];
  var _lookups = [];
  
  var _blockSize = null;
  var _totalSuffixes = null;
  var _inlineSuffixSize = null;
  var _inlineSuffixes = null;
  var _suffixes = null;
  
  this.count = function(term) {
    var region = this.lookup(term);
    return region[1] - region[0];
  }  
  
  this.find = function(term) {
    var region = this.lookup(term);
    return new Hits(term, region[0], region[1], _fulltextReader, this);
  } 

  this.lookup = function(term) {
    var preparedTerm = this.comparator(term);
    var region = _lookups[preparedTerm];
    if (region) return region;
    if (!this.prepare(preparedTerm)) {
      _lookups[preparedTerm] = [0, 0]
      return [0, 0]; 
    }
    var from = this.binarySearch(preparedTerm, 0, _suffixes.size(), false);
    if (from < _suffixes.size()) {
      var offset = this.indexToOffset(from);
      var data = _fulltextReader.getData(offset, term.length);
      if (this.comparator(data) == preparedTerm) {
        var to = this.binarySearch(preparedTerm, 0, _suffixes.size(), true);
        _lookups[preparedTerm] = [from, to]
        return [from, to];
      }
    }
    _lookups[preparedTerm] = [0, 0]
    return [0, 0];
  }   
  
  this.indexToOffset = function(suffixIndex) {
    return _suffixes.offset(suffixIndex);
  }
  
  this.indexToInfo = function(suffixIndex) {
    return _suffixes.get(suffixIndex);
  }
  
  this.prepare = function(term) {
    var re = new RegExp("(\\0|\\s|\\n)", "g");
    var shard = term.replace(re, "");
    shard = shard.slice(0, _shardSize);
    if (shard.length < _shardSize) throw new Error("Search term must be at least " + _shardSize + " characters");
    var url = _baseURL + '/' + shard;
    
    // Look for a cached version            
    item = _cache[url];
    if (item != null) {
      _reader = item["reader"];
      _totalSuffixes = item["totalSuffixes"];
      _blockSize = item["blockSize"];
      _inlineSuffixSize = item["inlineSuffixSize"];
      _inlineSuffixes = item["inlineSuffixes"];
      _suffixes = item["suffixes"];
      return true;
    }
      
    // Not in cache, lets build it and cache it
    try { _reader = new BinFileReader(url); } catch(e) { return false; }
    this.readHeaderAndSuffixes();
    var item = [];
    item["reader"] = _reader;
    item["totalSuffixes"] = _totalSuffixes;
    item["blockSize"] = _blockSize;
    item["inlineSuffixSize"] = _inlineSuffixSize;
    item["inlineSuffixes"] = _inlineSuffixes;
    item["suffixes"] = _suffixes;
    _cache[url] = item;     
    return true;
  }
  
  this.comparator = function(term) {
    return (term || '').toLowerCase();    
  }
  
  this.readHeaderAndSuffixes = function() {    
    // read header
    var block = _reader.read(12);
    _totalSuffixes = _reader.blockToNumber(block.slice(0, 3));
    _blockSize = _reader.blockToNumber(block.slice(4, 7));
    _inlineSuffixSize = _reader.blockToNumber(block.slice(8, 11));    
    _inlineSuffixes = [];
    
    if (_blockSize != 0) {
      var index = 0;
      for (var i=0; i<_totalSuffixes; i+= _blockSize) {
        var suffix = _reader.blockToString(_reader.read(_inlineSuffixSize));
        _inlineSuffixes[index++] = suffix;
      }
    }
    
    // skip padding
    var mod = _reader.pos() % 16;
    if (mod != 0) _reader.read(16 - mod);
      
    // load the suffixes
    _suffixes = new Suffixes(_reader, _totalSuffixes);        
  }
  
  this.binarySearch = function(term, from, to, upper) {
    var region = this.binarySearchInlineSuffixes(term, from, to, upper);
    from = region[0];
    to = region[1];
    var tsize = term.length;
    while (from < to) {
      var middle = Math.floor((from + to) / 2);
      var pivot = this.comparator(_fulltextReader.getData(_suffixes.offset(middle), tsize));
      if ((!upper && term <= pivot) || (upper && term < pivot)) {
        to = middle;
      } else {
        from = middle + 1;
      }
    }
    return from;          
  }
  
  this.binarySearchInlineSuffixes = function(term, from, to, upper) {
    if (_blockSize == 0) return [from, to];
    var tsize = term.length;
    while (to - from > _blockSize) {
      var middle = Math.floor((from + to) / 2);
      var quotient = Math.floor(middle / _blockSize);
      var mod = middle % _blockSize;
      var pivot = this.comparator(_inlineSuffixes[quotient]);      
      if (tsize <= _inlineSuffixSize) {
        if ((!upper && term <= pivot) || (upper && term < pivot.slice(0, tsize))) { 
          to = middle;
        } else {
          from = middle + 1;
        }
      } else if (term.slice(0, _inlineSuffixSize) < pivot) {
        to = middle;
      } else {
        var lastChar = pivot.charCodeAt(pivot.length-1);
        pivot = pivot.slice(0, pivot.length-1) + String.fromCharCode(lastChar + 1);
        if (term > pivot) {
          from = middle + 1;
        } else {
          pivot = this.comparator(_fulltextReader.getData(_suffixes.offset(middle), tsize));
          if ((!upper && term <= pivot) || (upper && term < pivot)) {
            to = middle;
          } else {
            from = middle + 1;
          }
        }  
      }    
    }     
    return [from, to];
  }
}