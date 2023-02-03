function remove(id, btn)
{
	tr = btn.parentElement.parentElement
	name = tr.getElementsByClassName("info")[0].children[0].children[0].innerHTML
	supplier = tr.getElementsByClassName("info")[0].children[0].children[1].innerHTML

	if (!confirm("Are you sure you want to remove " + name + " by " + supplier + "?"))
	{
		return;
	}
	var url = "/shoppingcart/" + id + "/delete";
	var params = "";
	var xhr = new XMLHttpRequest();
	xhr.open("POST", url, true);

	//Send the proper header information along with the request
	xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

	xhr.onreadystatechange = () => {
		if (xhr.readyState === 4)
		{
			if (xhr.response == "DEL")
			{
				tr.remove();
			}
		}
	}

	xhr.send(params);
}

function change_amount(id, pol, btn)
{
	tr = btn.parentElement.parentElement.parentElement
	name = tr.getElementsByClassName("info")[0].children[0].children[0].innerHTML
	supplier = tr.getElementsByClassName("info")[0].children[0].children[1].innerHTML
	value = tr.getElementsByClassName("amount")[0].getElementsByTagName("h3")[0]

	var url = "/shoppingcart/" + id + "/update";
	var params = "pol="+pol;
	var xhr = new XMLHttpRequest();
	xhr.open("POST", url, true);

	//Send the proper header information along with the request
	xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

	xhr.onreadystatechange = () => {
		if (xhr.readyState === 4)
		{
			if (xhr.response == "DEL")
			{
				tr.remove();
			}
			else if (xhr.response == "DEC")
			{
				value.innerHTML = (parseInt(value.innerHTML.substring(0, value.innerHTML.length - 2), 10) - 1) + "st";
			}
			else if (xhr.response == "ADD")
			{
				value.innerHTML = (parseInt(value.innerHTML.substring(0, value.innerHTML.length - 2), 10) + 1) + "st";
			}
		}
	}

	xhr.send(params);
}
