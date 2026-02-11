const API_BASE = 'http://localhost:3000/api';

let currentPage = 1;
let currentFilters = {};

// DOM Elements
const keywordInput = document.getElementById('keyword');
const locationInput = document.getElementById('location');
const searchBtn = document.getElementById('searchBtn');
const remoteOnlyCheckbox = document.getElementById('remoteOnly');
const sortBySelect = document.getElementById('sortBy');
const salaryMinInput = document.getElementById('salaryMin');
const loadingDiv = document.getElementById('loading');
const resultsDiv = document.getElementById('results');
const paginationDiv = document.getElementById('pagination');
const prevPageBtn = document.getElementById('prevPage');
const nextPageBtn = document.getElementById('nextPage');
const pageInfo = document.getElementById('pageInfo');

// Event Listeners
searchBtn.addEventListener('click', () => performSearch(1));
prevPageBtn.addEventListener('click', () => performSearch(currentPage - 1));
nextPageBtn.addEventListener('click', () => performSearch(currentPage + 1));

// Allow Enter key to search
keywordInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') performSearch(1);
});
locationInput.addEventListener('keypress', (e) => {
  if (e.key === 'Enter') performSearch(1);
});

// Main Search Function
async function performSearch(page = 1) {
  currentPage = page;
  
  // Build query parameters
  const params = new URLSearchParams({
    q: keywordInput.value || 'paralegal',
    location: locationInput.value || 'United States',
    page: page,
    page_size: 25,
    sort_by: sortBySelect.value
  });

  if (remoteOnlyCheckbox.checked) {
    params.set('remote', 'true');
  }

  if (salaryMinInput.value) {
    params.set('salary_min_usd', salaryMinInput.value);
  }

  // Store current filters
  currentFilters = Object.fromEntries(params);

  // Show loading state
  loadingDiv.classList.remove('hidden');
  resultsDiv.innerHTML = '';
  paginationDiv.classList.add('hidden');

  try {
    const response = await fetch(`${API_BASE}/search?${params.toString()}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    
    // Hide loading
    loadingDiv.classList.add('hidden');
    
    // Display results
    displayResults(data.results);
    
    // Update pagination
    updatePagination(data.results.length);
    
  } catch (error) {
    loadingDiv.classList.add('hidden');
    resultsDiv.innerHTML = `
      <div class="no-results">
        ❌ Error loading jobs: ${error.message}
        <br><br>
        <small>Please check your API credentials and try again.</small>
      </div>
    `;
    console.error('Search error:', error);
  }
}

// Display Results
function displayResults(jobs) {
  if (!jobs || jobs.length === 0) {
    resultsDiv.innerHTML = `
      <div class="no-results">
        😕 No jobs found. Try adjusting your search criteria.
      </div>
    `;
    return;
  }

  resultsDiv.innerHTML = jobs.map(job => createJobCard(job)).join('');
}

// Create Job Card HTML
function createJobCard(job) {
  const salary = formatSalary(job.salary_min_usd, job.salary_max_usd);
  const postedDate = formatDate(job.posted_at);
  const source = job.source.toUpperCase();
  
  return `
    <div class="job-card">
      <div class="job-header">
        <div>
          <h2 class="job-title">${escapeHtml(job.title)}</h2>
          <div class="job-company">${escapeHtml(job.company)}</div>
        </div>
        <span class="job-badge">${source}</span>
      </div>
      
      <div class="job-details">
        <span>📍 ${escapeHtml(job.location)}</span>
        <span>📅 ${postedDate}</span>
        ${job.remote ? '<span>🏠 Remote</span>' : ''}
      </div>
      
      <div class="job-description">
        ${escapeHtml(job.description_snippet || 'No description available')}
      </div>
      
      <div class="job-footer">
        <div class="job-salary">${salary}</div>
        <a href="${job.url}" target="_blank" rel="noopener noreferrer" class="apply-btn">
          Apply Now →
        </a>
      </div>
    </div>
  `;
}

// Format Salary
function formatSalary(min, max) {
  if (!min && !max) return 'Salary not specified';
  
  const formatNum = (num) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(num);
  };
  
  if (min && max) {
    return `${formatNum(min)} - ${formatNum(max)}`;
  } else if (min) {
    return `From ${formatNum(min)}`;
  } else {
    return `Up to ${formatNum(max)}`;
  }
}

// Format Date
function formatDate(dateString) {
  if (!dateString) return 'Date unknown';
  
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now - date);
  const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  
  return date.toLocaleDateString('en-US', { 
    month: 'short', 
    day: 'numeric', 
    year: 'numeric' 
  });
}

// Update Pagination
function updatePagination(resultsCount) {
  if (resultsCount === 0) {
    paginationDiv.classList.add('hidden');
    return;
  }
  
  paginationDiv.classList.remove('hidden');
  pageInfo.textContent = `Page ${currentPage}`;
  
  // Disable previous button on first page
  prevPageBtn.disabled = currentPage === 1;
  
  // Disable next button if fewer results than page size
  nextPageBtn.disabled = resultsCount < 25;
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
  if (!text) return '';
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// Initial search on page load
window.addEventListener('DOMContentLoaded', () => {
  performSearch(1);
});
